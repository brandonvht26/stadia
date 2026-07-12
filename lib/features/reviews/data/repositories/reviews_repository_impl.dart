import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> submitReview({
    required String receptionId,
    required int rating,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      await _supabase.from('reviews').insert({
        'user_id': userId,
        'reception_id': receptionId,
        'rating': rating,
        'comment': comment,
      });
    } on PostgrestException catch (e) {
      // 23505 es el código de Postgres para 'unique_violation'
      if (e.code == '23505') {
        throw Exception('Ya has calificado esta recepción.');
      }
      throw Exception('Error al enviar reseña: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al enviar reseña: $e');
    }
  }
}
