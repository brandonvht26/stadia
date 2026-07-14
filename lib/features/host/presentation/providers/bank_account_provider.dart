import 'package:flutter/material.dart';
import '../../data/repositories/host_repository_impl.dart';

class BankAccountProvider extends ChangeNotifier {
  final HostRepositoryImpl _repository;
  
  BankAccountProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  String accountNumber = '';
  String bankName = '';
  String accountType = 'savings'; // Default

  Future<bool> loadBankAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final account = await _repository.getMyBankAccount();
      if (account != null) {
        accountNumber = account.accountNumber;
        bankName = account.bankName;
        accountType = account.accountType;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setAccountNumber(String value) {
    accountNumber = value;
    notifyListeners();
  }

  void setBankName(String value) {
    bankName = value;
    notifyListeners();
  }

  void setAccountType(String value) {
    accountType = value;
    notifyListeners();
  }

  Future<bool> save() async {
    if (accountNumber.trim().isEmpty || bankName.trim().isEmpty) {
      _error = 'Por favor completa todos los campos.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.saveBankAccount(
        accountNumber: accountNumber.trim(),
        bankName: bankName.trim(),
        accountType: accountType,
      );

      await loadBankAccount();
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
