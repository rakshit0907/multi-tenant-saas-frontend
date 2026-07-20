import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    debugPrint("SPLASH CHECK START");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    debugPrint("TOKEN: $token");

    await Future.delayed(const Duration(seconds: 2));

    if (token == null) {
      debugPrint("NO TOKEN → LOGIN");

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    bool isExpired = JwtDecoder.isExpired(token);

    debugPrint("IS EXPIRED: $isExpired");

    if (isExpired) {
      debugPrint("TOKEN EXPIRED → LOGIN");

      await prefs.remove('token');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      debugPrint("TOKEN VALID → DASHBOARD");

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}