import '../entities/reservation_entity.dart';

abstract class MyReservationsRepository {
  Future<List<ReservationEntity>> getMyReservations();
  Future<void> cancelReservation(String reservationId);
}
