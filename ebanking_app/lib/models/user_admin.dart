// ─── UserAdminModel ───────────────────────────────────────
class UserAdminModel {
  final int          id;
  final String       username;
  final String       email;
  final String       firstName;
  final String       lastName;
  final String?      phone;
  final bool         fa2Enabled;
  final List<String> roles;
  final int          accountCount;

  UserAdminModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.fa2Enabled,
    required this.roles,
    required this.accountCount,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get primaryRole => roles.isNotEmpty ? roles.first : 'ROLE_CLIENT';

  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id:           (json['id'] as num).toInt(),
      username:     json['username']  as String? ?? '',
      email:        json['email']     as String? ?? '',
      firstName:    json['firstName'] as String? ?? '',
      lastName:     json['lastName']  as String? ?? '',
      phone:        json['phone']     as String?,
      fa2Enabled:   json['fa2Enabled'] as bool? ?? false,
      roles:        (json['roles'] as List?)
                        ?.map((e) => e.toString()).toList() ?? [],
      accountCount: (json['accountCount'] as num?)?.toInt() ?? 0,
    );
  }
}
