import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../models/service_model.dart';

class ReservationsRepositoryImpl implements ReservationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<ServiceEntity>> getServicesForReception(String receptionId) async {
    final response = await _supabase
        .from('services')
        .select()
        .eq('reception_id', receptionId);

    return (response as List<dynamic>)
        .map((json) => ServiceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DateTime>> getReservedDates(String receptionId) async {
    final response = await _supabase
        .from('reservations')
        .select('event_date')
        .eq('reception_id', receptionId)
        .inFilter('status', ['pending', 'confirmed']);

    return (response as List<dynamic>).map((row) {
      // row['event_date'] es un string como '2026-07-15' o '2026-07-15T00:00:00Z'
      return DateTime.parse(row['event_date'].toString());
    }).toList();
  }

  @override
  Future<String> createPendingReservation({
    required String receptionId,
    required DateTime eventDate,
    required List<ServiceEntity> services,
    required double totalAmount,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      // 1. Insertar en reservations
      final reservationResponse = await _supabase
          .from('reservations')
          .insert({
            'user_id': userId,
            'reception_id': receptionId,
            'event_date': eventDate.toIso8601String(),
            'total_amount': totalAmount,
            'status': 'pending',
          })
          .select('id')
          .single();

      final reservationId = reservationResponse['id'] as String;

      // 2. Insertar en reservation_services
      if (services.isNotEmpty) {
        try {
          final servicesData = services.map((service) => {
            'reservation_id': reservationId,
            'service_id': service.id,
            'price_at_booking': service.price,
          }).toList();

          await _supabase.from('reservation_services').insert(servicesData);
        } catch (e) {
          // Riesgo de inconsistencia de datos si falla esta inserción:
          // Quedaría una reserva con status 'pending' sin sus servicios asociados en BD.
          // Como no tenemos un rollback transaccional manual aquí, documentamos el riesgo.
          throw Exception('Reserva creada pero falló la inserción de servicios: $e');
        }
      }

      return reservationId;
    } catch (e) {
      throw Exception('Error al crear la reserva pendiente: $e');
    }
  }

  @override
  Future<String> createPaymentIntent(String reservationId) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-payment-intent',
        body: {'reservationId': reservationId},
      );

      final data = response.data;
      if (data == null) {
        throw Exception('No se recibió respuesta del servidor.');
      }
      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return data['clientSecret'] as String;
    } catch (e) {
      throw Exception('Error al crear intento de pago: $e');
    }
  }

  @override
  Future<bool> confirmReservationPayment(String reservationId) async {
    try {
      final response = await _supabase.functions.invoke(
        'confirm-reservation-payment',
        body: {'reservationId': reservationId},
      );

      final data = response.data;
      if (data == null) {
        throw Exception('No se recibió respuesta del servidor al confirmar.');
      }
      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return data['status'] == 'confirmed';
    } catch (e) {
      throw Exception('Error al confirmar pago de reserva: $e');
    }
  }
}
