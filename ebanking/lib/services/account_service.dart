import 'dart:convert';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../models/account.dart';

class AccountService {

  Future<List<Account>> getMyAccounts() async {
    final response = await ApiClient.get(
        '${AppConstants.accountsUrl}/my-accounts');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Account.fromJson(json)).toList();
    }

    // ✅ CORRECTION : message clair selon le code HTTP
    if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    }

    if (response.statusCode == 403) {
      throw Exception('Accès refusé.');
    }

    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  Future<bool> updateAccount(
    int accountId, {
    String? nickname,
    String? currency,
    String? status,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nickname != null) body['nickname'] = nickname;
      if (currency != null) body['currency'] = currency;
      if (status != null)   body['status']   = status;

      final response = await ApiClient.patch(
        '${AppConstants.accountsUrl}/$accountId',
        body: body,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}