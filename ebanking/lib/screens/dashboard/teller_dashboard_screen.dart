import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/deposit_service.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../models/deposit_request.dart';

class TellerDashboardScreen extends StatefulWidget {
  const TellerDashboardScreen({super.key});

  @override
  State<TellerDashboardScreen> createState() => _TellerDashboardScreenState();
}

class _TellerDashboardScreenState extends State<TellerDashboardScreen>
    with SingleTickerProviderStateMixin {

  final _depositService     = DepositService();
  final _transactionService = TransactionService();
  final _authService        = AuthService();

  final _otpController = TextEditingController(); // ✅ AJOUTÉ

  List<DepositRequestModel> _pendingRequests = [];
  bool _loading    = true;
  bool _otpLoading = false; // ✅ AJOUTÉ
  String? _username;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _otpController.dispose(); // ✅ AJOUTÉ
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _username = await _authService.getSavedUsername();
    final requests = await _depositService.getPendingRequests();
    if (!mounted) return;
    setState(() {
      _pendingRequests = requests;
      _loading = false;
    });
    _fadeController..reset()..forward();
  }

  Future<void> _approve(DepositRequestModel req) async {
    HapticFeedback.mediumImpact();
    final success = await _depositService.approveRequest(req.id);
    if (!mounted) return;
    if (success) {
      _showSnack('Deposit of \$${req.amount.toStringAsFixed(2)} approved ✓',
          const Color(0xFF1A6B3A));
      _loadData();
    } else {
      _showSnack('Failed to approve request', const Color(0xFFB03A3A));
    }
  }

  Future<void> _reject(DepositRequestModel req) async {
    HapticFeedback.heavyImpact();
    final success = await _depositService.rejectRequest(req.id);
    if (!mounted) return;
    if (success) {
      _showSnack('Request rejected', const Color(0xFFB03A3A));
      _loadData();
    } else {
      _showSnack('Failed to reject request', const Color(0xFFB03A3A));
    }
  }

  // ✅ AJOUTÉ : valider le code OTP de retrait
  Future<void> _validateOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty || code.length != 6) {
      _showSnack('Enter a valid 6-digit code', const Color(0xFFB03A3A));
      return;
    }

    setState(() => _otpLoading = true);
    HapticFeedback.lightImpact();

    final success = await _transactionService.validateWithdrawal(code);
    if (!mounted) return;
    setState(() => _otpLoading = false);

    if (success) {
      _otpController.clear();
      HapticFeedback.mediumImpact();
      _showSnack('Withdrawal validated successfully ✓', const Color(0xFF1A6B3A));
    } else {
      HapticFeedback.heavyImpact();
      _showSnack('Invalid or expired code', const Color(0xFFB03A3A));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFFC9A84C)))
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFFC9A84C),
                        backgroundColor: const Color(0xFF1A2540),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            // ✅ AJOUTÉ : Section OTP retrait
                            _buildOtpSection(),
                            const SizedBox(height: 24),

                            // Section dépôts en attente
                            Text('Deposit Requests',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12, letterSpacing: 1,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),

                            if (_pendingRequests.isEmpty)
                              _buildEmpty()
                            else
                              ..._pendingRequests.map((req) =>
                                _DepositRequestCard(
                                  request: req,
                                  onApprove: () => _approve(req),
                                  onReject:  () => _reject(req),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ✅ AJOUTÉ : Widget section OTP
  Widget _buildOtpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE07070).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Titre
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE07070).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pin_rounded,
                color: Color(0xFFE07070), size: 18),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Validate Withdrawal',
                style: TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Enter the OTP code shown by the client',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),

        const SizedBox(height: 16),

        // Champ OTP
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    fontFamily: 'monospace'),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.15),
                      fontSize: 22,
                      letterSpacing: 8,
                      fontFamily: 'monospace'),
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _otpLoading ? null : _validateOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07070),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _otpLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Validate',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF4A90D9), Color(0xFF6BB3F0)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.badge_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Teller Portal',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(_username ?? '',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
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
        ]),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(children: [
            Expanded(child: _StatItem(
              label: 'Pending',
              value: '${_pendingRequests.length}',
              color: const Color(0xFFC9A84C),
              icon: Icons.pending_actions_rounded,
            )),
            Container(width: 1, height: 40, color: Colors.white12),
            Expanded(child: _StatItem(
              label: 'To Process',
              value: _pendingRequests.isEmpty ? '-'
                  : '\$${_pendingRequests.fold(0.0, (s, r) => s + r.amount).toStringAsFixed(0)}',
              color: const Color(0xFF3DBA7B),
              icon: Icons.account_balance_wallet_rounded,
            )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF3DBA7B).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF3DBA7B), size: 48),
        ),
        const SizedBox(height: 16),
        const Text('No pending requests',
            style: TextStyle(color: Colors.white,
                fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('All deposit requests have been processed',
            style: TextStyle(color: Colors.white38, fontSize: 13)),
      ])),
    );
  }
}

// ─── Deposit Request Card ─────────────────────────────────
class _DepositRequestCard extends StatelessWidget {
  final DepositRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DepositRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90D9).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF4A90D9), size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(request.clientName,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text('•••• ${request.accountNumber.length > 4
                  ? request.accountNumber.substring(
                      request.accountNumber.length - 4)
                  : request.accountNumber}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ]),
          Text('\$${request.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Color(0xFF3DBA7B),
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ]),

        if (request.description != null && request.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(request.description!,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],

        const SizedBox(height: 10),
        Text(request.createdAt,
            style: const TextStyle(color: Colors.white24, fontSize: 11)),

        const SizedBox(height: 14),
        Divider(color: Colors.white.withOpacity(0.05), height: 1),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: onReject,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07070).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFE07070).withOpacity(0.3)),
                ),
                child: const Center(child: Text('Reject',
                    style: TextStyle(color: Color(0xFFE07070),
                        fontWeight: FontWeight.w600, fontSize: 13))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onApprove,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3DBA7B), Color(0xFF52D68F)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text('Approve Deposit',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 13))),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final IconData icon;
  const _StatItem({required this.label, required this.value,
      required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(
          color: color, fontSize: 18, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
    ]);
  }
}