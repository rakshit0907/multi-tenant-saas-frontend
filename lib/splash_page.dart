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
    print("SPLASH CHECK START");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    print("TOKEN: $token");

    await Future.delayed(const Duration(seconds: 2));

    if (token == null) {
      print("NO TOKEN → LOGIN");

      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    bool isExpired = JwtDecoder.isExpired(token);

    print("IS EXPIRED: $isExpired");

    if (isExpired) {
      print("TOKEN EXPIRED → LOGIN");

      await prefs.remove('token');
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      print("TOKEN VALID → DASHBOARD");

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