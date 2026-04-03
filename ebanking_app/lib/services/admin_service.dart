import 'dart:convert';
import 'package:ebanking/models/audit_log.dart';

import '../core/constants.dart';
import '../core/api_client.dart';
import '../models/user_admin.dart';
import '../models/account.dart';

class AdminService {
  static const String _base = '${AppConstants.baseUrl}/api/admin';

  Future<List<UserAdminModel>> getAllUsers() async {
    try {
      final r = await ApiClient.get('$_base/users');
      if (r.statusCode == 200) {
        final List data = jsonDecode(r.body);
        return data.map((j) => UserAdminModel.fromJson(j)).toList();
      }
      return [];
    } catch (_) { return []; }
  }

  Future<List<Account>> getAllAccounts() async {
    try {
      final r = await ApiClient.get('$_base/accounts');
      if (r.statusCode == 200) {
        final List data = jsonDecode(r.body);
        return data.map((j) => Account.fromJson(j)).toList();
      }
      return [];
    } catch (_) { return []; }
  }

  Future<bool> blockAccount(int accountId) async {
    try {
      final r = await ApiClient.post('$_base/accounts/$accountId/block');
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<bool> unblockAccount(int accountId) async {
    try {
      final r = await ApiClient.post('$_base/accounts/$accountId/unblock');
      return r.statusCode == 200;
    } catch (_) { return false; }
  }

  Future<List<AuditLogModel>> getAuditLogs() async {
    try {
      final r = await ApiClient.get('$_base/audit-logs');
      if (r.statusCode == 200) {
        final List data = jsonDecode(r.body);
        return data.map((j) => AuditLogModel.fromJson(j)).toList();
      }
      return [];
    } catch (_) { return []; }
  }
}