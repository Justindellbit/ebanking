import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/Withdrawal_Otp.dart';
import '../../widgets/auth_widgets.dart';

/// Affiché après que le CLIENT a demandé un retrait.
/// Montre le code OTP à présenter au TELLER.
class WithdrawalOtpScreen extends StatefulWidget {
  final WithdrawalOtpModel otpData;

  const WithdrawalOtpScreen({super.key, required this.otpData});

  @override
  State<WithdrawalOtpScreen> createState() => _WithdrawalOtpScreenState();
}

class _WithdrawalOtpScreenState extends State<WithdrawalOtpScreen> {
  late int _secondsLeft;
  Timer? _timer;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.otpData.expiresInMinutes * 60;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _expired = true;
          t.cancel();
        }
      });
    });
  }

  String get _timeDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      _secondsLeft / (widget.otpData.expiresInMinutes * 60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            const BackgroundDecor(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Back ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
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
                    ),

                    const Spacer(),

                    // ── Icon ──
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE07070).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE07070).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.credit_card_rounded,
                          color: Color(0xFFE07070), size: 32),
                    ),
                    const SizedBox(height: 20),

                    const Text('Withdrawal Code',
                        style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Show this code to the bank teller\nto complete your withdrawal',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // ── Code OTP ──
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.otpData.otpCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                            backgroundColor: Color(0xFF1A6B3A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _expired
                                ? [Colors.white10, Colors.white10]
                                : [
                                    const Color(0xFFE07070).withOpacity(0.1),
                                    const Color(0xFFE07070).withOpacity(0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _expired
                                ? Colors.white12
                                : const Color(0xFFE07070).withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Column(children: [
                          Text(
                            _expired ? 'EXPIRED' : widget.otpData.otpCode,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: _expired
                                  ? Colors.white24
                                  : const Color(0xFFE07070),
                              letterSpacing: 8,
                            ),
                          ),
                          if (!_expired) ...[
                            const SizedBox(height: 8),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              const Icon(Icons.copy_rounded,
                                  color: Colors.white38, size: 14),
                              const SizedBox(width: 4),
                              Text('Tap to copy',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ]),
                          ],
                        ]),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Timer ──
                    if (!_expired) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _secondsLeft > 120
                                ? const Color(0xFF3DBA7B)
                                : _secondsLeft > 60
                                    ? const Color(0xFFC9A84C)
                                    : const Color(0xFFE07070),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Expires in $_timeDisplay',
                        style: TextStyle(
                            color: _secondsLeft > 60
                                ? Colors.white38
                                : const Color(0xFFE07070),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ] else ...[
                      const ErrorBanner(
                          message: 'Code expired. Request a new withdrawal.'),
                    ],

                    const SizedBox(height: 32),

                    // ── Info card ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Column(children: [
                        _InfoRow(
                            label: 'Amount',
                            value:
                                '\$${widget.otpData.amount.toStringAsFixed(2)}'),
                        _InfoRow(
                            label: 'Account',
                            value: '•••• ${widget.otpData.accountNumber.substring(
                                widget.otpData.accountNumber.length > 4
                                    ? widget.otpData.accountNumber.length - 4
                                    : 0)}'),
                      ]),
                    ),

                    const Spacer(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}