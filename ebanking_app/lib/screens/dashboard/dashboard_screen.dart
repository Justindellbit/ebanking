import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../services/account_service.dart';
import '../../services/auth_service.dart';
import '../../models/account.dart';
import '../accountdetail/accountdetail_screen.dart'; // ✅ CORRECTION : décommenté

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _accountService = AccountService();
  final _authService = AuthService();

  bool _loading = true;
  List<Account> _accounts = [];
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadAccounts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _accountService.getMyAccounts();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
      _fadeController
        ..reset()
        ..forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  double get _totalBalance =>
      _accounts.fold(0.0, (sum, a) => sum + a.balance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFC9A84C)))
                    : _errorMessage != null
                        ? _buildError()
                        : _accounts.isEmpty
                            ? _buildEmpty()
                            : _buildAccountList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('EBanking Pro',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ]),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white54, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (!_loading && _accounts.isNotEmpty) _buildTotalCard(),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total Portfolio',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    letterSpacing: 0.5)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3DBA7B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.shield_outlined,
                    color: Color(0xFF3DBA7B), size: 12),
                const SizedBox(width: 4),
                Text('Secured',
                    style: TextStyle(
                        color: const Color(0xFF3DBA7B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            '\$${_totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_accounts.length} account${_accounts.length > 1 ? 's' : ''}',
            style: TextStyle(
                color: Colors.white.withOpacity(0.35), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _loadAccounts,
        color: const Color(0xFFC9A84C),
        backgroundColor: const Color(0xFF1A2540),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          itemCount: _accounts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text('My Accounts',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
              );
            }
            final account = _accounts[index - 1];
            return _AccountCard(
              account: account,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AccountDetailScreen(
                    account: account,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet_outlined,
              size: 48, color: Color(0xFFC9A84C)),
        ),
        const SizedBox(height: 20),
        const Text('No accounts yet',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Contact your bank to open an account',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.white30, size: 48),
        const SizedBox(height: 16),
        Text(_errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _loadAccounts,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Retry',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ─── Account Card Widget ────────────────────────────────
class _AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback onTap;

  const _AccountCard({required this.account, required this.onTap});

  Color get _typeColor {
    switch (account.accountType.toUpperCase()) {
      case 'SAVINGS':
        return const Color(0xFF3DBA7B);
      case 'CHECKING':
        return const Color(0xFF4A90D9);
      default:
        return const Color(0xFFC9A84C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last4 = account.number
        .substring(max(0, account.number.length - 4));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    account.accountType.toUpperCase(),
                    style: TextStyle(
                        color: _typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                ),
                Row(children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3DBA7B)),
                  ),
                  const SizedBox(width: 5),
                  Text(account.status,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ]),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Balance',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  Text(
                    '${account.currency} ${account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ]),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white24, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            const SizedBox(height: 14),
            Text(
              '•••• •••• •••• $last4',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 13,
                  letterSpacing: 2,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}