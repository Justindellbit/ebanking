import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {

  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  int _currentStep = 0;

  // Step 1
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _usernameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _phoneController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();
  bool _obscurePassword      = true;
  bool _obscureConfirm       = true;
  bool _fa2Enabled           = false;

  // Step 2
  String _accountType = 'CHECKING';
  String _currency    = 'USD';
  final _accountTypes = ['CHECKING', 'SAVINGS'];
  final _currencies   = ['USD', 'EUR', 'MAD', 'GBP', 'CAD', 'CHF'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  String? _validateStep1() {
    if (_firstNameController.text.trim().isEmpty) return 'First name is required';
    if (_lastNameController.text.trim().isEmpty)  return 'Last name is required';
    if (_usernameController.text.trim().length < 3) return 'Username must be at least 3 characters';
    if (!RegExp(r'^[\w.-]+@[\w-]+\.[a-z]{2,}$').hasMatch(_emailController.text.trim())) {
      return 'Enter a valid email address';
    }
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    if (_passwordController.text.length < 8) return 'Password must be at least 8 characters';
    if (_passwordController.text != _confirmController.text) return 'Passwords do not match';
    return null;
  }

  void _nextStep() {
    final error = _validateStep1();
    if (error != null) { setState(() => _errorMessage = error); return; }
    setState(() { _errorMessage = null; _currentStep = 1; });
    _fadeController..reset()..forward();
  }

  void _prevStep() {
    setState(() { _errorMessage = null; _currentStep = 0; });
    _fadeController..reset()..forward();
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    HapticFeedback.lightImpact();

    final result = await _authService.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      firstName:   _firstNameController.text.trim(),
      lastName:    _lastNameController.text.trim(),
      phone:       _phoneController.text.trim(),
      fa2Enabled:  _fa2Enabled,
      accountType: _accountType,
      currency:    _currency,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Auto-login après register
      final loginResult = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (loginResult.isSuccess && loginResult.jwt != null) {
        final jwt = loginResult.jwt!;
        // ✅ CORRECTION : saveRole manquait ici
        await _authService.saveToken(jwt.token);
        await _authService.saveUsername(_usernameController.text.trim());
        await _authService.saveRole(jwt.primaryRole);

        HapticFeedback.mediumImpact();
        if (!mounted) return;

        // Rediriger selon le rôle (nouveau compte = toujours ROLE_CLIENT)
        if (jwt.isAdmin) {
          Navigator.pushReplacementNamed(context, '/admin-dashboard');
        } else if (jwt.isTeller) {
          Navigator.pushReplacementNamed(context, '/teller-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // Auto-login échoué → retour au login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Please sign in.'),
          backgroundColor: Color(0xFF1A6B3A),
        ));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      setState(() { _isLoading = false; _errorMessage = result.errorMessage; });
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
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildStepIndicator(),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(children: [
        GestureDetector(
          onTap: _currentStep == 0 ? () => Navigator.pop(context) : _prevStep,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_currentStep == 0 ? 'Personal Info' : 'Account Setup',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Step ${_currentStep + 1} of 2',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(children: [
        _StepDot(index: 0, current: _currentStep, label: 'Personal'),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentStep >= 1
                    ? [const Color(0xFFC9A84C), const Color(0xFFE8C97A)]
                    : [Colors.white12, Colors.white12],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        _StepDot(index: 1, current: _currentStep, label: 'Account'),
      ]),
    );
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      const Text('Tell us about yourself',
          style: TextStyle(fontFamily: 'Georgia', fontSize: 22,
              fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      const Text('Fill in your personal information',
          style: TextStyle(color: Colors.white38, fontSize: 13)),
      const SizedBox(height: 28),

      Row(children: [
        Expanded(child: BankingField(controller: _firstNameController,
            hint: 'First name', icon: Icons.person_outline_rounded)),
        const SizedBox(width: 12),
        Expanded(child: BankingField(controller: _lastNameController,
            hint: 'Last name', icon: Icons.person_outline_rounded)),
      ]),
      const SizedBox(height: 14),
      BankingField(controller: _usernameController,
          hint: 'Username', icon: Icons.alternate_email_rounded),
      const SizedBox(height: 14),
      BankingField(controller: _emailController,
          hint: 'Email address', icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 14),
      BankingField(controller: _phoneController,
          hint: 'Phone (optional)', icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone),
      const SizedBox(height: 14),
      BankingField(
        controller: _passwordController,
        hint: 'Password',
        icon: Icons.lock_outline_rounded,
        obscure: _obscurePassword,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      const SizedBox(height: 14),
      BankingField(
        controller: _confirmController,
        hint: 'Confirm password',
        icon: Icons.lock_outline_rounded,
        obscure: _obscureConfirm,
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38, size: 20),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      const SizedBox(height: 20),

      // 2FA Toggle
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _fa2Enabled
                ? const Color(0xFFC9A84C).withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security_rounded, color: Color(0xFFC9A84C), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Two-Factor Authentication',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const Text('Extra security for your account',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          Switch(
            value: _fa2Enabled,
            onChanged: (v) => setState(() => _fa2Enabled = v),
            activeColor: const Color(0xFFC9A84C),
            inactiveTrackColor: Colors.white12,
          ),
        ]),
      ),

      if (_errorMessage != null) ...[
        const SizedBox(height: 16),
        ErrorBanner(message: _errorMessage!),
      ],
      const SizedBox(height: 28),
      GoldButton(label: 'Continue', isLoading: false, onTap: _nextStep),
      const SizedBox(height: 20),
      Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: RichText(text: TextSpan(
            text: 'Already a member? ',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
            children: const [TextSpan(text: 'Sign in',
                style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.w600))],
          )),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      const Text('Setup your account',
          style: TextStyle(fontFamily: 'Georgia', fontSize: 22,
              fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 4),
      const Text('Choose your account type and currency',
          style: TextStyle(color: Colors.white38, fontSize: 13)),
      const SizedBox(height: 32),

      const Text('Account Type',
          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
      const SizedBox(height: 12),
      Row(children: _accountTypes.map((type) {
        final selected = _accountType == type;
        final icon = type == 'CHECKING'
            ? Icons.account_balance_wallet_rounded
            : Icons.savings_rounded;
        final desc = type == 'CHECKING' ? 'Daily transactions' : 'Long-term savings';
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _accountType = type),
            child: Container(
              margin: EdgeInsets.only(right: type == _accountTypes.first ? 12 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFC9A84C).withOpacity(0.1)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected ? const Color(0xFFC9A84C) : Colors.white12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon,
                    color: selected ? const Color(0xFFC9A84C) : Colors.white38,
                    size: 24),
                const SizedBox(height: 10),
                Text(type,
                    style: TextStyle(
                        color: selected ? const Color(0xFFC9A84C) : Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ]),
            ),
          ),
        );
      }).toList()),

      const SizedBox(height: 28),
      const Text('Currency',
          style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10, runSpacing: 10,
        children: _currencies.map((c) {
          final selected = _currency == c;
          return GestureDetector(
            onTap: () => setState(() => _currency = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFC9A84C).withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? const Color(0xFFC9A84C) : Colors.white12),
              ),
              child: Text(c,
                  style: TextStyle(
                      color: selected ? const Color(0xFFC9A84C) : Colors.white54,
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          );
        }).toList(),
      ),

      const SizedBox(height: 28),

      // Récapitulatif
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(children: [
          _SummaryRow(label: 'Name',
              value: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'),
          _SummaryRow(label: 'Username', value: _usernameController.text.trim()),
          _SummaryRow(label: 'Account', value: _accountType),
          _SummaryRow(label: 'Currency', value: _currency),
          _SummaryRow(label: '2FA', value: _fa2Enabled ? 'Enabled ✓' : 'Disabled'),
        ]),
      ),

      if (_errorMessage != null) ...[
        const SizedBox(height: 16),
        ErrorBanner(message: _errorMessage!),
      ],
      const SizedBox(height: 28),
      GoldButton(label: 'Create My Account', isLoading: _isLoading, onTap: _submit),
      const SizedBox(height: 20),
      const SecurityBadge(),
      const SizedBox(height: 24),
    ]);
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepDot({required this.index, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final done   = current > index;
    final active = current == index;
    final color  = (done || active) ? const Color(0xFFC9A84C) : Colors.white24;
    return Column(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (done || active)
              ? const Color(0xFFC9A84C).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: done
              ? const Icon(Icons.check_rounded, color: Color(0xFFC9A84C), size: 14)
              : Text('${index + 1}',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    ]);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white,
            fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}