import 'dart:io';
import '../../../discovery/domain/entities/reception_entity.dart';
import '../entities/bank_account_entity.dart';
import '../entities/new_reception_entity.dart';
import '../entities/new_service_entity.dart';

abstract class HostRepository {
  Future<String> createReception(NewReceptionEntity data);
  Future<void> addServicesToReception(String receptionId, List<NewServiceEntity> services);
  Future<List<ReceptionEntity>> getMyReceptions();
  Future<String> uploadReceptionPhoto(String receptionId, File imageFile, int orderIndex);
  Future<void> updatePhotoOrder(List<String> orderedMediaIds);
  Future<void> deleteReceptionPhoto(String mediaId, String storagePath);
  Future<String> createVerificationPaymentIntent(String receptionId);
  Future<bool> confirmVerificationPayment(String receptionId);
  Future<BankAccountEntity?> getMyBankAccount();
  Future<void> saveBankAccount({required String accountNumber, required String bankName, required String accountType});
}
