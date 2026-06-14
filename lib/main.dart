import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'splash_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🚀 Splash is entry point
      home: const SplashPage(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> login(BuildContext context) async {
    print("LOGIN BUTTON CLICKED");

    final url = Uri.parse('http://10.0.2.2:3000/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": "rakshit@test.com",
        "password": "123456"
      }),
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("LOGIN SUCCESS FLOW");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);

      // ✅ Navigate properly
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      print("Login failed: ${data['message']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => login(context),
          child: const Text('Login'),
        ),
      ),
    );
  }
}