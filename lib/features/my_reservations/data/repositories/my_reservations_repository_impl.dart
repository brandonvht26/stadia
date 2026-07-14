import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/my_reservations_repository.dart';

class MyReservationsRepositoryImpl implements MyReservationsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<List<ReservationEntity>> getMyReservations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      // 1. Obtener las reservas con un join a receptions para traer el título
      final response = await _supabase
          .from('reservations')
          .select('''
            id,
            reception_id,
            event_date,
            total_amount,
            status,
            reschedule_count,
            receptions (
              title,
              host_id
            )
          ''')
          .eq('user_id', userId)
          .order('event_date', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        return [];
      }

      // Extraer IDs de recepción únicos de las reservas para buscar reseñas
      final receptionIds = data.map((r) => r['reception_id'] as String).toSet().toList();

      // 2. Obtener reseñas del usuario para esas recepciones
      // Constraint en BD asegura que solo haya máximo una reseña por (user_id, reception_id)
      final reviewsResponse = await _supabase
          .from('reviews')
          .select('reception_id')
          .eq('user_id', userId)
          .inFilter('reception_id', receptionIds);

      final List<dynamic> reviewsData = reviewsResponse as List<dynamic>;
      final reviewedReceptionIds = reviewsData.map((r) => r['reception_id'] as String).toSet();

      // 3. Mapear todo a entidades
      return data.map((json) {
        final recData = json['receptions'] as Map<String, dynamic>?;
        final title = recData != null ? recData['title'] as String : 'Recepción desconocida';
        final hostId = recData != null ? recData['host_id'] as String : '';
        final recId = json['reception_id'] as String;

        return ReservationEntity(
          id: json['id'] as String,
          receptionId: recId,
          receptionTitle: title,
          hostId: hostId,
          eventDate: DateTime.parse(json['event_date'].toString()),
          totalAmount: (json['total_amount'] as num).toDouble(),
          status: json['status'] as String,
          hasReview: reviewedReceptionIds.contains(recId),
          rescheduleCount: json['reschedule_count'] as int? ?? 0,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener mis reservas: $e');
    }
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      await _supabase
          .from('reservations')
          .update({'status': 'cancelled'})
          .eq('id', reservationId);
    } catch (e) {
      throw Exception('Error al cancelar la reserva: $e');
    }
  }

  @override
  Future<void> rescheduleReservation({required String reservationId, required DateTime newDate}) async {
    try {
      final formattedDate = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
      
      final response = await _supabase.functions.invoke(
        'reschedule-reservation',
        body: {'reservationId': reservationId, 'newDate': formattedDate},
      );

      final data = response.data;
      if (data != null && data['error'] != null) {
        throw Exception(data['error']);
      }
    } on FunctionException catch (e) {
      if (e.details != null && e.details is Map && (e.details as Map).containsKey('error')) {
        throw Exception((e.details as Map)['error']);
      }
      throw Exception('Error desconocido al reagendar: ${e.details ?? e.toString()}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
