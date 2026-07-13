import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/entities/reception_photo_entity.dart';
import '../../../discovery/domain/entities/reception_entity.dart';
import '../../../discovery/data/models/reception_model.dart';
import '../../domain/entities/new_reception_entity.dart';
import '../../domain/entities/new_service_entity.dart';
import '../../domain/repositories/host_repository.dart';

class HostRepositoryImpl implements HostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<String> createReception(NewReceptionEntity data) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await _supabase.from('receptions').insert({
        'host_id': userId,
        'title': data.title,
        'description': data.description,
        'base_price': data.basePrice,
        'latitude': data.latitude,
        'longitude': data.longitude,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al crear recepción: $e');
    }
  }

  @override
  Future<void> addServicesToReception(String receptionId, List<NewServiceEntity> services) async {
    if (services.isEmpty) return;

    try {
      final servicesData = services.map((s) => {
        'reception_id': receptionId,
        'name': s.name,
        'price': s.price,
      }).toList();

      await _supabase.from('services').insert(servicesData);
    } catch (e) {
      throw Exception('Error al agregar servicios a la recepción: $e');
    }
  }

  @override
  Future<List<ReceptionEntity>> getMyReceptions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado.');
    }

    try {
      final response = await _supabase
          .from('receptions')
          .select('*, reception_media(*)')
          .eq('host_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => ReceptionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener mis recepciones: $e');
    }
  }

  @override
  Future<String> uploadReceptionPhoto(String receptionId, File imageFile, int orderIndex) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$receptionId/$timestamp.jpg';

      await _supabase.storage
          .from('reception-photos')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage
          .from('reception-photos')
          .getPublicUrl(filePath);

      final newUrl = '$publicUrl?t=$timestamp';

      final response = await _supabase.from('reception_media').insert({
        'reception_id': receptionId,
        'media_url': newUrl,
        'order_index': orderIndex,
      }).select('id').single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error al subir la foto de la recepción: $e');
    }
  }

  @override
  Future<void> updatePhotoOrder(List<String> orderedMediaIds) async {
    try {
      for (int i = 0; i < orderedMediaIds.length; i++) {
        await _supabase.from('reception_media').update({
          'order_index': i,
        }).eq('id', orderedMediaIds[i]);
      }
    } catch (e) {
      throw Exception('Error al actualizar el orden de las fotos: $e');
    }
  }

  @override
  Future<void> deleteReceptionPhoto(String mediaId, String storagePath) async {
    try {
      await _supabase.storage.from('reception-photos').remove([storagePath]);
      await _supabase.from('reception_media').delete().eq('id', mediaId);
    } catch (e) {
      throw Exception('Error al eliminar la foto: $e');
    }
  }

  @override
  Future<String> createVerificationPaymentIntent(String receptionId) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-verification-payment-intent',
        body: {'receptionId': receptionId},
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
      throw Exception('Error al crear intento de pago de verificación: $e');
    }
  }

  @override
  Future<bool> confirmVerificationPayment(String receptionId) async {
    try {
      final response = await _supabase.functions.invoke(
        'confirm-verification-payment',
        body: {'receptionId': receptionId},
      );

      final data = response.data;
      if (data == null) {
        throw Exception('No se recibió respuesta del servidor al confirmar.');
      }
      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      return data['success'] == true && data['isVerified'] == true;
    } catch (e) {
      throw Exception('Error al confirmar pago de verificación: $e');
    }
  }

  @override
  Future<BankAccountEntity?> getMyBankAccount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await _supabase
          .from('bank_accounts')
          .select()
          .eq('host_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return BankAccountEntity.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener la cuenta bancaria: $e');
    }
  }

  @override
  Future<void> saveBankAccount({
    required String accountNumber,
    required String bankName,
    required String accountType,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');

      await _supabase.from('bank_accounts').upsert({
        'host_id': userId,
        'account_number': accountNumber,
        'bank_name': bankName,
        'account_type': accountType,
      }, onConflict: 'host_id');
    } catch (e) {
      throw Exception('Error al guardar la cuenta bancaria: $e');
    }
  }

  @override
  Future<List<ReceptionPhotoEntity>> getReceptionPhotos(String receptionId) async {
    try {
      final response = await _supabase
          .from('reception_media')
          .select()
          .eq('reception_id', receptionId)
          .order('order_index', ascending: true);

      return (response as List).map((json) => ReceptionPhotoEntity.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener las fotos de la recepción: $e');
    }
  }

  @override
  Future<void> deleteReception(String receptionId) async {
    try {
      await _supabase.from('receptions').delete().eq('id', receptionId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Error al eliminar la recepción: $e');
    }
  }
}
