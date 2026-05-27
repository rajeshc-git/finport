import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finport/screens/dashboard_screen.dart';
import 'package:finport/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0D0D11),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FinportApp());
}

class FinportApp extends StatefulWidget {
  const FinportApp({super.key});

  static _FinportAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_FinportAppState>();

  @override
  State<FinportApp> createState() => _FinportAppState();
}

class _FinportAppState extends State<FinportApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAuthenticated = false;

  ThemeMode get themeMode => _themeMode;
  bool get isAuthenticated => _isAuthenticated;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void login() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void logout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5856D6),
        secondary: Color(0xFF30B0C7),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: const Color(0xFF1C1C1E),
        displayColor: const Color(0xFF1C1C1E),
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0D11),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6C5DD3),
        secondary: Color(0xFF00F2FE),
        surface: Color(0xFF161622),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Finport',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: _isAuthenticated
            ? const DashboardScreen(key: ValueKey('dashboard'))
            : LoginScreen(
                key: const ValueKey('login'),
                onLoginSuccess: login,
              ),
      ),
    );
  }
}
