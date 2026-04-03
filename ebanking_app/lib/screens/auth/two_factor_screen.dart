import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen>
    with SingleTickerProviderStateMixin {

  final _authService = AuthService();
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes  = List.generate(6, (_) => FocusNode());

  bool    _isLoading   = false;
  String? _error;
  String  _username    = '';
  bool    _initialized = false;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(
        parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
      _username    = args?['username'] as String? ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String get _fullCode => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    final code = _fullCode;
    if (code.length < 6) {
      setState(() => _error = 'Enter the complete 6-digit code');
      return;
    }
    final codeInt = int.tryParse(code);
    if (codeInt == null) {
      setState(() => _error = 'Invalid code');
      return;
    }

    setState(() { _isLoading = true; _error = null; });
    HapticFeedback.lightImpact();

    // ✅ validate2FA est bien défini dans auth_service.dart
    final result = await _authService.validate2FA(_username, codeInt);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess && result.jwt != null) {
      final jwt = result.jwt!;
      await _authService.saveToken(jwt.token);
      await _authService.saveUsername(_username);
      await _authService.saveRole(jwt.primaryRole);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      if (jwt.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (jwt.isTeller) {
        Navigator.pushReplacementNamed(context, '/teller-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      HapticFeedback.heavyImpact();
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      setState(() => _error = result.errorMessage ?? 'Invalid code');
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Dernier champ → fermer clavier seulement
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

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
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
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
                            child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white54, size: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFC9A84C).withOpacity(0.35),
                            blurRadius: 24, offset: const Offset(0, 8),
                          )],
                        ),
                        child: const Icon(Icons.security_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      const Text('Two-Factor Authentication',
                          style: TextStyle(
                              fontFamily: 'Georgia', fontSize: 22,
                              fontWeight: FontWeight.w700, color: Colors.white),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('Enter the 6-digit code from\nGoogle Authenticator',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 14, height: 1.5),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFC9A84C).withOpacity(0.3)),
                        ),
                        child: Text(_username,
                            style: const TextStyle(
                                color: Color(0xFFC9A84C), fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) => Container(
                          width: 48, height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _focusNodes[index].hasFocus
                                  ? const Color(0xFFC9A84C)
                                  : Colors.white.withOpacity(0.1),
                              width: _focusNodes[index].hasFocus ? 2 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            focusNode:  _focusNodes[index],
                            textAlign:  TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w700),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                                counterText: '', border: InputBorder.none),
                            onChanged: (v) => _onDigitChanged(index, v),
                          ),
                        )),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        ErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 36),
                      GoldButton(
                          label: 'Verify Code',
                          isLoading: _isLoading,
                          onTap: _submit),
                      const SizedBox(height: 24),
                      Text('Code valid for 5 minutes',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}