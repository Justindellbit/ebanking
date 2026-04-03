import 'dart:convert';
import '../core/constants.dart';
import '../core/api_client.dart';
import '../models/transaction.dart';
import '../../models/Withdrawal_Otp.dart';

class TransactionService {

  // ─── Historique ─────────────────────────────────────────
  Future<List<Transaction>> getHistory(int accountId) async {
    try {
      final response = await ApiClient.get(
          '${AppConstants.transactionsUrl}/history/$accountId');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((j) => Transaction.fromJson(j)).toList();
      }
      return [];
    } catch (_) { return []; }
  }

  // ─── Dépôt ──────────────────────────────────────────────
  // ✅ CORRECTION : méthode était vide
  // Note : le dépôt nécessite le rôle TELLER ou ADMIN côté backend.
  // Un CLIENT qui clique "Deposit" recevra un 403 — c'est voulu.
  // Le flux correct : le client demande un dépôt → le teller le valide.
  Future<String?> deposit(int accountId, double amount) async {
    try {
      final response = await ApiClient.postWithParams(
        '${AppConstants.transactionsUrl}/deposit/$accountId',
        {'amount': amount.toString()},
      );
      if (response.statusCode == 200) {
        return null; // succès, pas d'erreur
      }
      if (response.statusCode == 403) {
        return 'Deposit must be validated by a teller. Please visit your branch.';
      }
      // Extraire le message d'erreur du backend
      try {
        final body = jsonDecode(response.body);
        return body['message'] ?? body['error'] ?? 'Deposit failed (${response.statusCode})';
      } catch (_) {
        return 'Deposit failed (${response.statusCode})';
      }
    } catch (e) {
      return e.toString();
    }
  }

  // ─── Retrait étape 1 : demander OTP ─────────────────────
  // ✅ CORRECTION : propagation de l'erreur backend (ex: solde insuffisant)
  Future<WithdrawalOtpModel?> requestWithdrawal(
      int accountId, double amount) async {
    final response = await ApiClient.postWithParams(
      '${AppConstants.transactionsUrl}/withdrawal/request/$accountId',
      {'amount': amount.toString()},
    );
    if (response.statusCode == 200) {
      return WithdrawalOtpModel.fromJson(jsonDecode(response.body));
    }
    // Extraire et relancer l'erreur pour que l'UI l'affiche
    try {
      final body = jsonDecode(response.body);
      final msg = body['message'] ?? body['error'] ?? 'Withdrawal failed';
      throw Exception(msg);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Withdrawal failed (${response.statusCode})');
    }
  }

  // ─── Retrait étape 2 : valider OTP ──────────────────────
  Future<bool> validateWithdrawal(String otpCode) async {
    try {
      final response = await ApiClient.postWithParams(
        '${AppConstants.transactionsUrl}/withdrawal/validate',
        {'otpCode': otpCode},
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }

  // ─── Virement ───────────────────────────────────────────
  Future<bool> transfer(int fromAccountId, String toAccountNumber,
      double amount, {String? description}) async {
    try {
      final params = {
        'toAccountNumber': toAccountNumber,
        'amount': amount.toString(),
        if (description != null) 'description': description,
      };
      final response = await ApiClient.postWithParams(
        '${AppConstants.transactionsUrl}/transfer/$fromAccountId',
        params,
      );
      return response.statusCode == 200;
    } catch (_) { return false; }
  }
}