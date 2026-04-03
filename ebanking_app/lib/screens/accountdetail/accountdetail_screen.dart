import 'package:ebanking/services/account_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../models/account.dart';
import '../transaction/transaction_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen>
    with SingleTickerProviderStateMixin {
  final _accountService = AccountService();
  late Account _account;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAccountSheet(
        account: _account,
        onSaved: (updatedAccount) {
          setState(() => _account = updatedAccount);
        },
        accountService: _accountService,
      ),
    );
  }

  void _goToOperation(String tab) {
    final tabIndex = {'deposit': 0, 'withdraw': 1, 'transfer': 2};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionScreen(
          accountId: _account.id,
          accountNumber: _account.number,
          accountBalance: _account.balance, // ✅ paramètre ajouté
          initialTab: tabIndex[tab] ?? 0,
        ),
      ),
    );
  }

  void _goToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionScreen(
          accountId: _account.id,
          accountNumber: _account.number,
          accountBalance: _account.balance, // ✅ paramètre ajouté
          initialTab: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last4 =
        _account.number.substring(max(0, _account.number.length - 4));
    final isActive = _account.status == 'ACTIVE';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditSheet,
        backgroundColor: const Color(0xFFC9A84C),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──
                  Row(children: [
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
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_account.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Text('•••• $last4',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ]),
                  ]),

                  const SizedBox(height: 32),

                  // ── Balance Card ──
                  _BalanceCard(account: _account),

                  const SizedBox(height: 32),

                  // ── Quick Actions ──
                  Text('Operations',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _OperationTile(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Deposit',
                        color: const Color(0xFF3DBA7B),
                        onTap: isActive
                            ? () => _goToOperation('deposit')
                            : null,
                      ),
                      _OperationTile(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Withdraw',
                        color: const Color(0xFFE07070),
                        onTap: isActive
                            ? () => _goToOperation('withdraw')
                            : null,
                      ),
                      _OperationTile(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Transfer',
                        color: const Color(0xFF6B5CE7),
                        onTap: isActive
                            ? () => _goToOperation('transfer')
                            : null,
                      ),
                      _OperationTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'History',
                        color: const Color(0xFF4A90D9),
                        onTap: _goToTransactions,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Account Info ──
                  Text('Account Details',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _InfoCard(account: _account),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Balance Card ────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final Account account;
  const _BalanceCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final isActive = account.status == 'ACTIVE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2540), Color(0xFF0F1829)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A84C).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Text('Available Balance',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    letterSpacing: 0.5)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF3DBA7B).withOpacity(0.15)
                    : const Color(0xFFE07070).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? const Color(0xFF3DBA7B)
                        : const Color(0xFFE07070),
                  ),
                ),
                const SizedBox(width: 5),
                Text(account.status,
                    style: TextStyle(
                        color: isActive
                            ? const Color(0xFF3DBA7B)
                            : const Color(0xFFE07070),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            '${account.currency} ${account.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          const SizedBox(height: 16),
          Text(
            '•••• •••• •••• ${account.number.substring(max(0, account.number.length - 4))}',
            style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
                letterSpacing: 2,
                fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

// ─── Operation Tile ──────────────────────────────────────
class _OperationTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _OperationTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ─── Info Card ───────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final Account account;
  const _InfoCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        _InfoRow(label: 'Account Number', value: account.accountNumber),
        _Divider(),
        _InfoRow(label: 'Type', value: account.accountType),
        _Divider(),
        _InfoRow(label: 'Currency', value: account.currency),
        _Divider(),
        _InfoRow(
            label: 'Nickname',
            value: account.nickname.isNotEmpty ? account.nickname : '—'),
        _Divider(),
        _InfoRow(label: 'Status', value: account.status),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(color: Colors.white.withOpacity(0.05), height: 1);
}

// ─── Edit Account Bottom Sheet ───────────────────────────
class _EditAccountSheet extends StatefulWidget {
  final Account account;
  final Function(Account) onSaved;
  final AccountService accountService;

  const _EditAccountSheet({
    required this.account,
    required this.onSaved,
    required this.accountService,
  });

  @override
  State<_EditAccountSheet> createState() => _EditAccountSheetState();
}

class _EditAccountSheetState extends State<_EditAccountSheet> {
  late TextEditingController _nicknameController;
  late String _selectedCurrency;
  late String _selectedStatus;
  bool _isSaving = false;

  final _currencies = ['USD', 'EUR', 'MAD', 'GBP', 'CAD', 'CHF'];
  final _statuses   = ['ACTIVE', 'BLOCKED'];

  @override
  void initState() {
    super.initState();
    _nicknameController =
        TextEditingController(text: widget.account.nickname);
    _selectedCurrency = widget.account.currency;
    _selectedStatus   = widget.account.status;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final success = await widget.accountService.updateAccount(
      widget.account.id,
      nickname: _nicknameController.text.trim().isNotEmpty
          ? _nicknameController.text.trim()
          : null,
      currency: _selectedCurrency != widget.account.currency
          ? _selectedCurrency
          : null,
      status: _selectedStatus != widget.account.status
          ? _selectedStatus
          : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      HapticFeedback.mediumImpact();
      final updated = Account(
        id: widget.account.id,
        accountNumber: widget.account.accountNumber,
        accountType: widget.account.accountType,
        balance: widget.account.balance,
        currency: _selectedCurrency,
        status: _selectedStatus,
        nickname: _nicknameController.text.trim(),
      );
      widget.onSaved(updated);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Account updated successfully'),
        backgroundColor: const Color(0xFF1A6B3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Update failed. Please try again.'),
        backgroundColor: const Color(0xFFB03A3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Edit Account',
              style: TextStyle(
                  fontFamily: 'Georgia',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),

          _SheetLabel('Nickname'),
          const SizedBox(height: 8),
          _SheetField(
            controller: _nicknameController,
            hint: 'Ex: My Savings, Travel Fund...',
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 20),

          _SheetLabel('Currency'),
          const SizedBox(height: 8),
          _SheetDropdown<String>(
            value: _selectedCurrency,
            items: _currencies,
            icon: Icons.currency_exchange_rounded,
            onChanged: (v) => setState(() => _selectedCurrency = v!),
          ),
          const SizedBox(height: 20),

          _SheetLabel('Status'),
          const SizedBox(height: 8),
          Row(children: _statuses.map((s) {
            final selected = _selectedStatus == s;
            final color = s == 'ACTIVE'
                ? const Color(0xFF3DBA7B)
                : const Color(0xFFE07070);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedStatus = s),
                child: Container(
                  margin: EdgeInsets.only(
                      right: s == _statuses.first ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.15)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected ? color : Colors.white12),
                  ),
                  child: Center(
                    child: Text(s,
                        style: TextStyle(
                            color: selected ? color : Colors.white38,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ),
            );
          }).toList()),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: Colors.white54, fontSize: 12, letterSpacing: 0.5));
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _SheetField(
      {required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
          prefixIcon: Icon(icon, color: const Color(0xFFC9A84C), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SheetDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final IconData icon;
  final ValueChanged<T?> onChanged;
  const _SheetDropdown(
      {required this.value,
      required this.items,
      required this.icon,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: const Color(0xFF1A2540),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white38),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Row(children: [
                    Icon(icon, color: const Color(0xFFC9A84C), size: 16),
                    const SizedBox(width: 10),
                    Text(e.toString()),
                  ])))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}