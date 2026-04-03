
// ─── AuditLogModel ────────────────────────────────────────
class AuditLogModel {
  final int     id;
  final String  username;
  final String  action;
  final String? description;
  final String? ipAddress;
  final String? deviceInfo;
  final String  createdAt;

  AuditLogModel({
    required this.id,
    required this.username,
    required this.action,
    this.description,
    this.ipAddress,
    this.deviceInfo,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id:          (json['id'] as num).toInt(),
      username:    json['username']    as String? ?? 'system',
      action:      json['action']      as String? ?? '',
      description: json['description'] as String?,
      ipAddress:   json['ipAddress']   as String?,
      deviceInfo:  json['deviceInfo']  as String?,
      createdAt:   _fmt(json['createdAt'] as String?),
    );
  }

  static String _fmt(String? raw) {
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