class BankAccountEntity {
  final String id;
  final String accountNumber;
  final String bankName;
  final String accountType;

  BankAccountEntity({
    required this.id,
    required this.accountNumber,
    required this.bankName,
    required this.accountType,
  });

  factory BankAccountEntity.fromJson(Map<String, dynamic> json) {
    return BankAccountEntity(
      id: json['id'] as String,
      accountNumber: json['account_number'] as String,
      bankName: json['bank_name'] as String,
      accountType: json['account_type'] as String,
    );
  }
}
