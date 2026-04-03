import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'screens/login/login_screen.dart';
import 'screens/register/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/auth/two_factor_screen.dart';
import 'screens/dashboard/teller_dashboard_screen.dart';
import 'screens/dashboard/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EBanking Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A84C),
          secondary: Color(0xFF3DBA7B),
          error: Color(0xFFE07070),
          surface: Color(0xFF111827),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      // ✅ Toutes les navigations utilisent les routes nommées
      routes: {
        '/login':     (context) => const LoginScreen(),
        '/register':  (context) => const RegisterScreen(),
        '/dashboard':   (context) => const DashboardScreen(),
        '/2fa-verify':       (context) => const TwoFactorScreen(),
        '/teller-dashboard': (context) => const TellerDashboardScreen(),
        '/admin-dashboard':  (context) => const AdminDashboardScreen(),
      },
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final isLoggedIn = await _authService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Rediriger selon le rôle sauvegardé
    final role = await _authService.getRole();
    if (!mounted) return;

    if (role == 'ROLE_ADMIN') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (role == 'ROLE_TELLER') {
      Navigator.pushReplacementNamed(context, '/teller-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC9A84C), Color(0xFFE8C97A)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'EBanking Pro',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFFC9A84C),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}