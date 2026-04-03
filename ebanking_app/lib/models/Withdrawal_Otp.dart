class WithdrawalOtpModel {
  final String otpCode;
  final int    expiresInMinutes;
  final String accountNumber;
  final double amount;

  WithdrawalOtpModel({
    required this.otpCode,
    required this.expiresInMinutes,
    required this.accountNumber,
    required this.amount,
  });

  factory WithdrawalOtpModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalOtpModel(
      otpCode:          json['otpCode']          as String? ?? '',
      expiresInMinutes: json['expiresInMinutes']  as int?    ?? 10,
      accountNumber:    json['accountNumber']     as String? ?? '',
      amount:           (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}