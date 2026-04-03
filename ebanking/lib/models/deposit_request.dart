class DepositRequestModel {
  final int     id;
  final int     accountId;
  final String  accountNumber;
  final String  clientName;
  final double  amount;
  final String? description;
  final String  status;   // PENDING | APPROVED | REJECTED
  final String  createdAt;
  final String? processedBy;

  DepositRequestModel({
    required this.id,
    required this.accountId,
    required this.accountNumber,
    required this.clientName,
    required this.amount,
    this.description,
    required this.status,
    required this.createdAt,
    this.processedBy,
  });

  bool get isPending  => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory DepositRequestModel.fromJson(Map<String, dynamic> json) {
    return DepositRequestModel(
      id:            (json['id']        as num).toInt(),
      accountId:     (json['accountId'] as num).toInt(),
      accountNumber: json['accountNumber'] as String? ?? '',
      clientName:    json['clientName']    as String? ?? 'Unknown',
      amount:        (json['amount']    as num?)?.toDouble() ?? 0.0,
      description:   json['description'] as String?,
      status:        json['status']       as String? ?? 'PENDING',
      createdAt:     _formatDate(json['createdAt'] as String?),
      processedBy:   json['processedBy'] as String?,
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2,'0')}/'
             '${dt.month.toString().padLeft(2,'0')}/'
             '${dt.year}  '
             '${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return raw; }
  }
}