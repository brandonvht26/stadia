import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reception_entity.dart';
import '../../domain/entities/discovery_filters_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../../../../core/services/location_service.dart';

// Manejador de estado para el feed de Discovery (ViewModel).
// Utiliza ChangeNotifier para ser proveído mediante Provider.

class DiscoveryProvider extends ChangeNotifier {
  final DiscoveryRepository _repository;

  DiscoveryProvider(this._repository) {
    _initRealtime();
    _loadAvailableServices();
    
    // Purgar la memoria caché del feed al cambiar de cuenta
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        reset();
      }
    });
  }

  RealtimeChannel? _receptionsChannel;
  RealtimeChannel? _favoritesChannel;
  RealtimeChannel? _mediaChannel;

  void _initRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final suffix = currentUserId ?? DateTime.now().millisecondsSinceEpoch.toString();

    _receptionsChannel = Supabase.instance.client.channel('discovery-receptions-$suffix');
    _receptionsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'receptions',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final id = newRecord['id'];
        final index = _receptions.indexWhere((r) => r.id == id);
        if (index != -1) {
          final existing = _receptions[index];
          _receptions[index] = existing.copyWith(
            title: newRecord['title'] ?? existing.title,
            basePrice: (newRecord['base_price'] as num?)?.toDouble() ?? existing.basePrice,
            isVerified: newRecord['is_verified'] ?? existing.isVerified,
            likesCount: newRecord['likes_count'] ?? existing.likesCount,
          );
          notifyListeners();
        }
      },
    ).subscribe();

    if (currentUserId != null) {
      _favoritesChannel = Supabase.instance.client.channel('discovery-favorites-$suffix');
      _favoritesChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'favorites',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUserId,
        ),
        callback: (payload) {
          final eventType = payload.eventType;
          String? receptionId;
          if (eventType == PostgresChangeEvent.insert) {
            receptionId = payload.newRecord['reception_id'];
          } else if (eventType == PostgresChangeEvent.delete) {
            receptionId = payload.oldRecord['reception_id'];
          }

          if (receptionId != null) {
            final index = _receptions.indexWhere((r) => r.id == receptionId);
            if (index != -1) {
              final isLiked = eventType == PostgresChangeEvent.insert;
              // likesCount will be updated by the receptions channel through the DB trigger
              _receptions[index] = _receptions[index].copyWith(isLikedByUser: isLiked);
              notifyListeners();
            }
          }
        },
      ).subscribe();
    }

    _mediaChannel = Supabase.instance.client.channel('discovery-media-$suffix');
    _mediaChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'reception_media',
      callback: (payload) {
        final eventType = payload.eventType;
        String? receptionId;
        String? mediaUrl;
        
        if (eventType == PostgresChangeEvent.insert) {
          receptionId = payload.newRecord['reception_id'];
          mediaUrl = payload.newRecord['media_url'];
        } else if (eventType == PostgresChangeEvent.delete) {
          receptionId = payload.oldRecord['reception_id'];
          mediaUrl = payload.oldRecord['media_url'];
        }

        if (receptionId != null && mediaUrl != null) {
          final index = _receptions.indexWhere((r) => r.id == receptionId);
          if (index != -1) {
            final existing = _receptions[index];
            List<String> newUrls = List.from(existing.imageUrls);
            
            if (eventType == PostgresChangeEvent.insert) {
              if (!newUrls.contains(mediaUrl)) {
                newUrls.add(mediaUrl);
              }
            } else if (eventType == PostgresChangeEvent.delete) {
              newUrls.remove(mediaUrl);
            }
            
            _receptions[index] = existing.copyWith(imageUrls: newUrls);
            notifyListeners();
          }
        }
      },
    ).subscribe();
  }

  DiscoveryFiltersEntity _currentFilters = const DiscoveryFiltersEntity();
  DiscoveryFiltersEntity get currentFilters => _currentFilters;

  List<String> _availableServices = [];
  List<String> get availableServices => _availableServices;

  final List<ReceptionEntity> _receptions = [];
  List<ReceptionEntity> get receptions => _receptions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  bool _locationPermissionDenied = false;
  bool get locationPermissionDenied => _locationPermissionDenied;

  int _currentPage = 0;
  final int _pageSize = 5; // Paginamos de 5 en 5 (o ajustarlo según preferencia)
  final LocationService _locationService = LocationService();

  /// Carga la siguiente página de recepciones.
  Future<void> loadMoreReceptions() async {
    // Prevenir llamadas simultáneas o si ya se llegó al final.
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newReceptions = await _repository.getReceptions(
        page: _currentPage,
        pageSize: _pageSize,
        filters: _currentFilters,
      );

      // Si hay un filtro de distancia activo, o si se desea calcular distancias globalmente, pedimos ubicación.
      double? userLat;
      double? userLng;
      
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _locationPermissionDenied = true;
      } else {
        _locationPermissionDenied = false;
        userLat = position.latitude;
        userLng = position.longitude;
      }

      // Procesar distancias y aplicar filtro de cercanía en memoria (client-side)
      List<ReceptionEntity> processedReceptions = [];
      for (var r in newReceptions) {
        double? distance;
        if (userLat != null && userLng != null && r.latitude != null && r.longitude != null) {
          distance = _locationService.calculateDistanceInKm(userLat, userLng, r.latitude!, r.longitude!);
        }
        
        final updatedReception = r.copyWith(distanceKm: distance);
        
        if (_currentFilters.maxDistanceKm != null) {
          if (distance != null && distance <= _currentFilters.maxDistanceKm!) {
            processedReceptions.add(updatedReception);
          }
        } else {
          processedReceptions.add(updatedReception);
        }
      }

      if (newReceptions.isEmpty || newReceptions.length < _pageSize) {
        _hasMore = false; // Fin de los resultados de Supabase
      }

      _receptions.addAll(processedReceptions);
      _currentPage++;
    } catch (e) {
      _error = 'Ocurrió un error al cargar el feed.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reinicia el feed desde cero (Pull to refresh).
  Future<void> refreshFeed() async {
    _receptions.clear();
    _currentPage = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
    await loadMoreReceptions();
  }

  /// Actualiza los filtros y recarga el feed
  Future<void> updateFilters(DiscoveryFiltersEntity newFilters) async {
    _currentFilters = newFilters;
    await refreshFeed();
  }

  /// Limpia los filtros y recarga el feed
  Future<void> clearFilters() async {
    _currentFilters = const DiscoveryFiltersEntity();
    await refreshFeed();
  }

  /// Limpia por completo el estado del provider (ideal para logout/cambio de cuenta)
  void reset() {
    _receptions.clear();
    _currentFilters = const DiscoveryFiltersEntity();
    _currentPage = 0;
    _hasMore = true;
    _isLoading = false;
    _error = null;
    _locationPermissionDenied = false;
    notifyListeners();
    // No recargamos aquí para evitar peticiones cuando el usuario acaba de desloguearse.
    // La pantalla se encargará de pedir loadMoreReceptions() en su initState.
  }

  /// Carga los servicios disponibles
  Future<void> _loadAvailableServices() async {
    try {
      _availableServices = await _repository.getAvailableServices();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading services: $e");
    }
  }

  /// Alterna el estado de "Me gusta" con actualización optimista de la UI.
  Future<void> toggleLike(String receptionId) async {
    final index = _receptions.indexWhere((r) => r.id == receptionId);
    if (index == -1) return;

    // Usamos el cliente directamente por ahora para mantener la simplicidad.
    // El repositorio internamente ya verifica qué usuario está ejecutando la acción.
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _error = 'Debes iniciar sesión para usar favoritos.';
      notifyListeners();
      return;
    }

    final reception = _receptions[index];
    final isCurrentlyLiked = reception.isLikedByUser;
    final newLikesCount = isCurrentlyLiked ? reception.likesCount - 1 : reception.likesCount + 1;

    // Actualización Optimista
    _receptions[index] = reception.copyWith(
      isLikedByUser: !isCurrentlyLiked,
      likesCount: newLikesCount,
    );
    notifyListeners();

    try {
      if (isCurrentlyLiked) {
        await _repository.unlikeReception(receptionId);
      } else {
        await _repository.likeReception(receptionId);
      }
    } catch (e) {
      // Revertir en caso de error
      _receptions[index] = reception; // reception contiene el estado anterior original
      _error = 'Error al actualizar el favorito.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_receptionsChannel != null) {
      Supabase.instance.client.removeChannel(_receptionsChannel!);
    }
    if (_favoritesChannel != null) {
      Supabase.instance.client.removeChannel(_favoritesChannel!);
    }
    if (_mediaChannel != null) {
      Supabase.instance.client.removeChannel(_mediaChannel!);
    }
    super.dispose();
  }
}
