class Transaction {
  final int id;
  final String transId;
  final double amount;
  final String type;
  final String description;
  final String date;
  final String status;

  Transaction({
    required this.id,
    required this.transId,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json['id'] as num).toInt(),
      transId: json['transId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      // Le backend renvoie LocalDateTime → format ISO 8601
      date: _formatDate(json['timestamp'] as String?),
      status: json['status'] as String? ?? '',
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}