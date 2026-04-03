class Account {
  final int id;
  final String accountNumber;
  final String accountType;
  final double balance;
  final String currency;
  final String status;
  final String nickname; // ✅ nouveau champ

  Account({
    required this.id,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.currency,
    required this.status,
    this.nickname = '',
  });

  String get number => accountNumber;

  /// Nom affiché : nickname si défini, sinon type du compte
  String get displayName =>
      nickname.isNotEmpty ? nickname : accountType;

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: (json['id'] as num).toInt(),
      accountNumber: json['accountNumber'] as String? ?? '',
      accountType: json['accountType'] as String? ?? 'CHECKING',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'ACTIVE',
      nickname: json['nickname'] as String? ?? '',
    );
  }
}