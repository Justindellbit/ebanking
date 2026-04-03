import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';
//import '../auth/two_factor_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    final result = await _authService.login(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess && result.jwt != null) {
      final jwt = result.jwt!;

      if (jwt.needs2FA) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/2fa-verify',
            arguments: {'username': username, 'tempToken': jwt.token});
        return;
      }

      await _authService.saveToken(jwt.token);
      await _authService.saveUsername(username);
      // Sauvegarder le rôle pour le routing
      final role = jwt.primaryRole;
      await _authService.saveRole(role);
      HapticFeedback.mediumImpact();
      if (!mounted) return;

      // Rediriger selon le rôle
      if (jwt.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (jwt.isTeller) {
        Navigator.pushReplacementNamed(context, '/teller-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = result.errorMessage);
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
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        const Center(child: BrandHeader()),
                        const SizedBox(height: 52),
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your secure account',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 36),
                        BankingField(
                          controller: _usernameController,
                          hint: 'Username',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        BankingField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          ErrorBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: 32),
                        GoldButton(
                          label: 'Sign In',
                          isLoading: _isLoading,
                          onTap: _login,
                        ),
                        const SizedBox(height: 28),
                        Row(children: [
                          Expanded(
                              child:
                                  Divider(color: Colors.white12, height: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR',
                                style: TextStyle(
                                    color: Colors.white24, fontSize: 11)),
                          ),
                          Expanded(
                              child:
                                  Divider(color: Colors.white12, height: 1)),
                        ]),
                        const SizedBox(height: 28),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: RichText(
                              text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 14),
                                children: const [
                                  TextSpan(
                                    text: 'Open an account',
                                    style: TextStyle(
                                      color: Color(0xFFC9A84C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const SecurityBadge(),
                        const SizedBox(height: 24),
                      ],
                    ),
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