import 'dart:convert';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../../models/deposit_request.dart';

class DepositService {

  static const String _baseUrl = '${AppConstants.baseUrl}/api/deposits';

  // ── CLIENT soumet une demande ─────────────────────────
  Future<DepositRequestModel?> requestDeposit(
      int accountId, double amount, {String? description}) async {
    try {
      final params = {
        'amount': amount.toString(),
        if (description != null && description.isNotEmpty)
          'description': description,
      };
      final response = await ApiClient.postWithParams(
          '$_baseUrl/request/$accountId', params);
      if (response.statusCode == 200) {
        return DepositRequestModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) { return null; }
  }

  // ── TELLER : liste des demandes PENDING ───────────────
  Future<List<DepositRequestModel>> getPendingRequests() async {
    try {
      final response = await ApiClient.get('$_baseUrl/pending');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => DepositRequestModel.fromJson(j)).toList();
      }
      return [];
    } catch (_) { return []; }
  }

  // ── TELLER : approuver ────────────────────────────────
  Future<bool> approveRequest(int requestId) async {
    try {
      final response = await ApiClient.post(
          '$_baseUrl/approve/$requestId');
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── TELLER : rejeter ──────────────────────────────────
  Future<bool> rejectRequest(int requestId) async {
    try {
      final response = await ApiClient.post(
          '$_baseUrl/reject/$requestId');
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ── Historique demandes d'un compte ───────────────────
  Future<List<DepositRequestModel>> getHistory(int accountId) async {
    try {
      final response = await ApiClient.get('$_baseUrl/history/$accountId');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => DepositRequestModel.fromJson(j)).toList();
      }
      return [];
    } catch (_) { return []; }
  }
}