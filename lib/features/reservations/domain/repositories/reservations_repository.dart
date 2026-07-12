import '../entities/service_entity.dart';

abstract class ReservationsRepository {
  /// Obtiene la lista de servicios adicionales disponibles para una recepción
  Future<List<ServiceEntity>> getServicesForReception(String receptionId);

  /// Obtiene las fechas que ya están reservadas ('pending' o 'confirmed') para bloquearlas en el calendario
  Future<List<DateTime>> getReservedDates(String receptionId);

  /// Crea una reserva en estado 'pending' y asocia los servicios seleccionados
  /// Retorna el ID de la reserva creada
  Future<String> createPendingReservation({
    required String receptionId,
    required DateTime eventDate,
    required List<ServiceEntity> services,
    required double totalAmount,
  });

  /// Invoca la Edge Function para crear el intento de pago con Stripe
  /// Retorna el clientSecret necesario para confirmar el pago en el cliente
  Future<String> createPaymentIntent(String reservationId);

  /// Invoca la Edge Function para confirmar con el backend que el pago se realizó
  /// Retorna true si status == 'confirmed'
  Future<bool> confirmReservationPayment(String reservationId);
}
