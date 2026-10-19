import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'services/api_service.dart';

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
    debugPrint('SPLASH CHECK START');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await Future.delayed(const Duration(seconds: 2));

    if (token == null || token.isEmpty) {
      debugPrint('NO TOKEN → LOGIN');

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      if (JwtDecoder.isExpired(token)) {
        debugPrint('TOKEN EXPIRED → LOGIN');

        await prefs.remove('token');

        if (!mounted) return;

        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await ApiService.getWorkspaces();

      debugPrint('SESSION VALID → DASHBOARD');

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      debugPrint('SESSION VALIDATION FAILED: $e');

      await prefs.remove('token');

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
