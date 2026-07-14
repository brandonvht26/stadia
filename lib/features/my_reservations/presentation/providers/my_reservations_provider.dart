import 'package:flutter/material.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/my_reservations_repository.dart';

class MyReservationsProvider extends ChangeNotifier {
  final MyReservationsRepository _repository;

  MyReservationsProvider(this._repository);

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
}
