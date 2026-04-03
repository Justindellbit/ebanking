class JwtResponse {
  final String       token;
  final String       type;
  final int?         id;
  final String       username;
  final String?      email;
  final bool         needs2FA;
  final List<String> roles;

  JwtResponse({
    required this.token,
    required this.type,
    required this.username,
    this.id,
    this.email,
    this.needs2FA = false,
    this.roles    = const [],
  });

  /// Rôle principal (le premier dans la liste)
  String get primaryRole => roles.isNotEmpty ? roles.first : 'ROLE_CLIENT';

  bool get isAdmin  => roles.contains('ROLE_ADMIN');
  bool get isTeller => roles.contains('ROLE_TELLER');
  bool get isClient => roles.contains('ROLE_CLIENT');

  factory JwtResponse.fromJson(Map<String, dynamic> json) {
    return JwtResponse(
      token:    json['token']    as String? ?? '',
      type:     json['type']     as String? ?? 'Bearer',
      id:       json['id']       != null ? (json['id'] as num).toInt() : null,
      username: json['username'] as String? ?? '',
      email:    json['email']    as String?,
      needs2FA: json['needs2FA'] as bool?   ?? false,
      roles:    (json['roles']   as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}