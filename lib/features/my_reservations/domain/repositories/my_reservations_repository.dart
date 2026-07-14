import '../entities/reservation_entity.dart';

abstract class MyReservationsRepository {
  Future<List<ReservationEntity>> getMyReservations();
  Future<void> cancelReservation(String reservationId);
  Future<void> rescheduleReservation({required String reservationId, required DateTime newDate});
}
