import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../services/deposit_service.dart';
import '../withdrawalOtp/withdrawalOtp_Screen.dart';

class TransactionScreen extends StatefulWidget {
  final int accountId;
  final String accountNumber;
  final double accountBalance; // ✅ AJOUTÉ : pour vérifier le solde avant OTP
  final int initialTab;

  const TransactionScreen({
    super.key,
    required this.accountId,
    required this.accountNumber,
    required this.accountBalance,
    this.initialTab = 0,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  final _transactionService = TransactionService();
  final _depositService     = DepositService(); // ✅ AJOUTÉ

  final _depositAmountController  = TextEditingController();
  final _withdrawAmountController = TextEditingController();
  final _transferAmountController = TextEditingController();
  final _toAccountController      = TextEditingController();

  bool _loading       = true;
  bool _actionLoading = false;
  List<Transaction> _transactions = [];
  late double _currentBalance; // ✅ solde mutable dans le state

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.accountBalance; // ✅ initialisé depuis le widget
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadTransactions();
  }

  @override
  void dispose() {
    _depositAmountController.dispose();
    _withdrawAmountController.dispose();
    _transferAmountController.dispose();
    _toAccountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final txs = await _transactionService.getHistory(widget.accountId);
    if (mounted) setState(() { _transactions = txs; _loading = false; });
  }

  double? _parseAmountFrom(TextEditingController c) {
    final amount = double.tryParse(c.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return null;
    }
    return amount;
  }

  // ─── Dépôt ──────────────────────────────────────────────
  // ✅ CORRECTION : utilise DepositService → /api/deposits/request
  Future<void> _performDeposit() async {
    final amount = _parseAmountFrom(_depositAmountController);
    if (amount == null) return;
    setState(() => _actionLoading = true);
    HapticFeedback.lightImpact();

    final result = await _depositService.requestDeposit(
        widget.accountId, amount);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (result != null) {
      _depositAmountController.clear();
      _showPending(
        'Deposit request of \$${amount.toStringAsFixed(2)} submitted.\n'
        'A teller will validate it shortly.',
      );
    } else {
      _showError('Failed to submit deposit request. Please try again.');
    }
  }

  // ─── Retrait ────────────────────────────────────────────
  // ✅ CORRECTION : vérification du solde côté Flutter avant d'appeler le backend
  Future<void> _performWithdraw() async {
    final amount = _parseAmountFrom(_withdrawAmountController);
    if (amount == null) return;

    if (amount > _currentBalance) {
      _showError(
        'Insufficient balance. '
        'Available: \$${_currentBalance.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _actionLoading = true);
    HapticFeedback.lightImpact();

    try {
      final otpData = await _transactionService.requestWithdrawal(
          widget.accountId, amount);
      if (!mounted) return;
      setState(() => _actionLoading = false);

      if (otpData != null) {
        _withdrawAmountController.clear();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WithdrawalOtpScreen(otpData: otpData),
          ),
        ).then((_) => _loadTransactions());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showError(msg);
    }
  }

  // ─── Virement ───────────────────────────────────────────
  Future<void> _performTransfer() async {
    final amount = _parseAmountFrom(_transferAmountController);
    final toAccountNumber = _toAccountController.text.trim();
    if (amount == null) return;
    if (toAccountNumber.isEmpty) {
      _showError('Enter destination account number');
      return;
    }
    if (amount > _currentBalance) {
      _showError(
        'Insufficient balance. '
        'Available: \$${_currentBalance.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _actionLoading = true);
    HapticFeedback.lightImpact();

    final success = await _transactionService.transfer(
        widget.accountId, toAccountNumber, amount);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    if (success) {
      _transferAmountController.clear();
      _toAccountController.clear();
      // ✅ Mettre à jour le solde affiché immédiatement
      setState(() => _currentBalance = _currentBalance - amount);
      _showSuccess('Transfer of \$${amount.toStringAsFixed(2)} sent');
      _loadTransactions();
    } else {
      _showError('Transfer failed. Check account number and balance.');
    }
  }

  void _showSuccess(String msg) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFF1A6B3A),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showPending(String msg) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFFC9A84C),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFFB03A3A),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final last4 = widget.accountNumber
        .substring(max(0, widget.accountNumber.length - 4));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white54, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Account',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('•••• •••• •••• $last4',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                ]),
                const Spacer(),
                // ✅ Solde visible dans l'AppBar
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Balance',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('\$${_currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFFC9A84C), fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Tab Bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Deposit'),
                  Tab(text: 'Withdraw'),
                  Tab(text: 'Transfer'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tab Views ──
            SizedBox(
              height: 210,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ActionPanel(
                    amountController: _depositAmountController,
                    isLoading: _actionLoading,
                    buttonLabel: 'Request Deposit',
                    buttonColor: const Color(0xFF3DBA7B),
                    icon: Icons.arrow_downward_rounded,
                    hint: 'Amount to deposit',
                    subtitle: 'Will be validated by a teller',
                    onAction: _performDeposit,
                  ),
                  _ActionPanel(
                    amountController: _withdrawAmountController,
                    isLoading: _actionLoading,
                    buttonLabel: 'Withdraw',
                    buttonColor: const Color(0xFFE07070),
                    icon: Icons.arrow_upward_rounded,
                    hint: 'Amount to withdraw',
                    subtitle: 'A one-time code will be generated',
                    onAction: _performWithdraw,
                  ),
                  _TransferPanel(
                    amountController: _transferAmountController,
                    toAccountController: _toAccountController,
                    isLoading: _actionLoading,
                    onAction: _performTransfer,
                  ),
                ],
              ),
            ),

            // ── History Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transactions',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12, letterSpacing: 1,
                          fontWeight: FontWeight.w600)),
                  GestureDetector(
                    onTap: _loadTransactions,
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFFC9A84C), size: 18),
                  ),
                ],
              ),
            ),

            // ── History List ──
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFFC9A84C)))
                  : _transactions.isEmpty
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.receipt_long_outlined,
                                color: Colors.white12, size: 48),
                            SizedBox(height: 12),
                            Text('No transactions yet',
                                style: TextStyle(
                                    color: Colors.white24, fontSize: 14)),
                          ]))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) =>
                              _TransactionTile(tx: _transactions[index]),
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Action Panel ────────────────────────────────────────
class _ActionPanel extends StatelessWidget {
  final TextEditingController amountController;
  final bool isLoading;
  final String buttonLabel;
  final Color buttonColor;
  final IconData icon;
  final String hint;
  final String? subtitle;
  final VoidCallback onAction;

  const _ActionPanel({
    required this.amountController,
    required this.isLoading,
    required this.buttonLabel,
    required this.buttonColor,
    required this.icon,
    required this.hint,
    this.subtitle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        _DarkField(
          controller: amountController,
          hint: hint,
          icon: Icons.attach_money_rounded,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(subtitle!,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onAction,
            icon: isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(icon, size: 18),
            label: Text(buttonLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Transfer Panel ──────────────────────────────────────
class _TransferPanel extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController toAccountController;
  final bool isLoading;
  final VoidCallback onAction;

  const _TransferPanel({
    required this.amountController,
    required this.toAccountController,
    required this.isLoading,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        _DarkField(
          controller: toAccountController,
          hint: 'Destination account number',
          icon: Icons.account_circle_outlined,
          keyboard: TextInputType.text,
        ),
        const SizedBox(height: 10),
        _DarkField(
          controller: amountController,
          hint: 'Amount (USD)',
          icon: Icons.attach_money_rounded,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onAction,
            icon: isLoading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Send Transfer',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Dark Field ──────────────────────────────────────────
class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          prefixIcon: Icon(icon, color: const Color(0xFFC9A84C), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  Color get _color {
    switch (tx.type.toLowerCase()) {
      case 'deposit':      return const Color(0xFF3DBA7B);
      case 'withdrawal':   return const Color(0xFFE07070);
      case 'transfer_out': return const Color(0xFFE07070);
      case 'transfer_in':  return const Color(0xFF3DBA7B);
      default:             return const Color(0xFF6B5CE7);
    }
  }

  IconData get _icon {
    switch (tx.type.toLowerCase()) {
      case 'deposit':      return Icons.arrow_downward_rounded;
      case 'withdrawal':   return Icons.arrow_upward_rounded;
      case 'transfer_out': return Icons.arrow_outward_rounded;
      case 'transfer_in':  return Icons.arrow_downward_rounded;
      default:             return Icons.swap_horiz_rounded;
    }
  }

  String get _sign {
    switch (tx.type.toLowerCase()) {
      case 'deposit':     return '+';
      case 'transfer_in': return '+';
      default:            return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_icon, color: _color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx.type.toUpperCase(),
                style: const TextStyle(color: Colors.white,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(tx.date,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        )),
        Text('$_sign\$${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(color: _color,
                fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }
}