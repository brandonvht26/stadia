import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reception_entity.dart';
import '../../domain/entities/discovery_filters_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../models/reception_model.dart';

// Implementación del repositorio de Discovery conectándose a Supabase.

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final SupabaseClient _supabaseClient;

  DiscoveryRepositoryImpl({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<List<String>> getAvailableServices() async {
    try {
      final response = await _supabaseClient
          .from('services')
          .select('name');
      final List<dynamic> data = response;
      final Set<String> uniqueServices = {};
      for (var item in data) {
        if (item['name'] != null) {
          uniqueServices.add(item['name'] as String);
        }
      }
      return uniqueServices.toList()..sort();
    } catch (e) {
      throw Exception('Error al obtener servicios disponibles: $e');
    }
  }

  @override
  Future<List<ReceptionEntity>> getReceptions({
    required int page,
    required int pageSize,
    DiscoveryFiltersEntity? filters,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      // NOTA TÉCNICA (MVP): 
      // Actualmente no usamos PostGIS en Supabase. Por tanto, no podemos hacer 
      // filtrado eficiente por radio geoespacial directamente en SQL aquí.
      // El filtrado por distancia (maxDistanceKm) se realiza en el cliente 
      // (DiscoveryProvider) DESPUÉS de recibir esta data. Para un dataset 
      // muy grande, esto debe migrarse a una función RPC o PostGIS.
      
      var query = _supabaseClient
          .from('receptions_with_rating')
          .select('*, reception_media(media_url, order_index), services(name)');

      // 1. Filtrado por "Solo me gustan" (Favoritos)
      if (filters != null && filters.onlyLiked) {
        final userId = _supabaseClient.auth.currentUser?.id;
        if (userId == null) return [];
        
        final favResponse = await _supabaseClient
            .from('favorites')
            .select('reception_id')
            .eq('user_id', userId);
            
        final List<dynamic> favData = favResponse;
        if (favData.isEmpty) {
          return []; // Si no hay favoritos y el filtro está activo, retornar vacío
        }
        
        final favIds = favData.map((e) => e['reception_id'] as String).toList();
        query = query.inFilter('id', favIds);
      }

      // 1.5. Filtrado por servicios
      if (filters != null && filters.selectedServices.isNotEmpty) {
        final srvResponse = await _supabaseClient
            .from('services')
            .select('reception_id')
            .inFilter('name', filters.selectedServices);
        
        final List<dynamic> srvData = srvResponse;
        final matchedReceptionIds = srvData.map((e) => e['reception_id'] as String).toSet().toList();
        
        if (matchedReceptionIds.isEmpty) {
          return []; // Si no hay recepciones con estos servicios, retornar vacío directamente.
        }
        query = query.inFilter('id', matchedReceptionIds);
      }

      // 2. Filtros de precio, rating, verificación y likes
      if (filters != null) {
        if (filters.minPrice != null) {
          query = query.gte('base_price', filters.minPrice!);
        }
        if (filters.maxPrice != null) {
          query = query.lte('base_price', filters.maxPrice!);
        }
        if (filters.minRating != null) {
          query = query.gte('avg_rating', filters.minRating!);
        }
        if (filters.isVerified != null) {
          query = query.eq('is_verified', filters.isVerified!);
        }
        if (filters.minLikes != null) {
          query = query.gte('likes_count', filters.minLikes!);
        }
        if (filters.maxLikes != null) {
          query = query.lte('likes_count', filters.maxLikes!);
        }
      }

      // 3. Búsqueda por texto (título o nombre de host)
      if (filters != null && filters.searchQuery != null && filters.searchQuery!.trim().isNotEmpty) {
        final q = filters.searchQuery!.trim();
        
        // Obtener IDs de hosts cuyo nombre coincida
        final profilesResponse = await _supabaseClient
            .from('profiles')
            .select('id')
            .or('first_name.ilike.%$q%,last_name.ilike.%$q%');
        
        final List<dynamic> profilesData = profilesResponse;
        final hostIds = profilesData.map((e) => e['id'] as String).toList();
        
        if (hostIds.isNotEmpty) {
          final hostIdsString = hostIds.join(',');
          query = query.or('title.ilike.%$q%,host_id.in.($hostIdsString)');
        } else {
          query = query.or('title.ilike.%$q%');
        }
      }

      // 4. Ordenamiento por defecto y paginación
      final response = await query
          .order('is_verified', ascending: false)
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> data = response;
      
      // Segunda consulta para mapear los "me gusta" del usuario actual
      final userId = _supabaseClient.auth.currentUser?.id;
      final Set<String> likedIds = {};
      
      if (userId != null && data.isNotEmpty) {
        final List<String> receptionIds = data.map((e) => e['id'] as String).toList();
        
        final favResponse = await _supabaseClient
            .from('favorites')
            .select('reception_id')
            .eq('user_id', userId)
            .inFilter('reception_id', receptionIds); // En versiones actuales supabase_flutter v2 usa inFilter, si falla cambiamos a in_
            
        final List<dynamic> favData = favResponse;
        for (var item in favData) {
          likedIds.add(item['reception_id'] as String);
        }
      }

      return data.map((json) {
        final id = json['id'] as String;
        return ReceptionModel.fromJson(json, isLikedByUser: likedIds.contains(id));
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener recepciones: $e');
    }
  }

  @override
  Future<void> likeReception(String receptionId) async {
    final currentUserId = _supabaseClient.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    await _supabaseClient.from('favorites').insert({
      'user_id': currentUserId,
      'reception_id': receptionId,
    });
  }

  @override
  Future<void> unlikeReception(String receptionId) async {
    final currentUserId = _supabaseClient.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    await _supabaseClient
        .from('favorites')
        .delete()
        .match({'user_id': currentUserId, 'reception_id': receptionId});
  }
}
