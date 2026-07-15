import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/my_reservations_repository.dart';

class MyReservationsProvider extends ChangeNotifier {
  final MyReservationsRepository _repository;

  MyReservationsProvider(this._repository) {
    _initRealtime();
  }

  RealtimeChannel? _reservationsChannel;

  void _initRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    
    final suffix = currentUserId;

    _reservationsChannel = Supabase.instance.client.channel('my-reservations-live-$suffix');
    _reservationsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'reservations',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: currentUserId,
      ),
      callback: (payload) {
        final eventType = payload.eventType;
        
        if (eventType == PostgresChangeEvent.update) {
          final newRecord = payload.newRecord;
          final id = newRecord['id'];
          final index = _reservations.indexWhere((r) => r.id == id);
          
          if (index != -1) {
            final existing = _reservations[index];
            _reservations[index] = existing.copyWith(
              status: newRecord['status'] ?? existing.status,
              totalAmount: (newRecord['total_price'] as num?)?.toDouble() ?? existing.totalAmount,
              eventDate: newRecord['reservation_date'] != null 
                  ? DateTime.tryParse(newRecord['reservation_date']) ?? existing.eventDate 
                  : existing.eventDate,
            );
            _sortReservations();
            notifyListeners();
          }
        } else if (eventType == PostgresChangeEvent.delete) {
          final id = payload.oldRecord['id'];
          _reservations.removeWhere((r) => r.id == id);
          notifyListeners();
        } else if (eventType == PostgresChangeEvent.insert) {
          // Since an INSERT might miss joined data (like reception details),
          // it's safer to just reload the list, or we could add a basic entity if we had all fields.
          // For now we just trigger a reload to get the full joined data.
          loadReservations();
        }
      },
    ).subscribe();
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'pending': return 0;
      case 'confirmed': return 1;
      case 'completed': return 2;
      case 'cancelled': return 3;
      default: return 4;
    }
  }

  void _sortReservations() {
    _reservations.sort((a, b) {
      final statusCompare = _statusPriority(a.status).compareTo(_statusPriority(b.status));
      if (statusCompare != 0) return statusCompare;
      return b.eventDate.compareTo(a.eventDate);
    });
  }
  List<ReservationEntity> _reservations = [];
  List<ReservationEntity> get reservations => _reservations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadReservations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reservations = await _repository.getMyReservations();
      _sortReservations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    try {
      await _repository.cancelReservation(reservationId);
      // Actualizamos el estado local
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] = _reservations[index].copyWith(status: 'cancelled');
        _sortReservations();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> rescheduleReservation(String reservationId, DateTime newDate) async {
    try {
      await _repository.rescheduleReservation(reservationId: reservationId, newDate: newDate);
      await loadReservations();
    } catch (e) {
      throw e;
    }
  }

  @override
  void dispose() {
    if (_reservationsChannel != null) {
      Supabase.instance.client.removeChannel(_reservationsChannel!);
    }
    super.dispose();
  }
}
