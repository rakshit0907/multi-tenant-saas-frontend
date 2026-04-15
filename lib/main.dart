import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/dashboard': (context) => DashboardPage(),
      },
      home: FutureBuilder(
        future: checkLogin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          }

          if (snapshot.data == true) {
            return DashboardPage();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

 Future<void> login(BuildContext context) async {
  final url = Uri.parse('http://10.0.2.2:3000/auth/login'); // FIXED URL

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "email": "debug@gmail.com",
      "password": "123456"
    }),
  );

  print("Status Code: ${response.statusCode}");
  print("Response Body: ${response.body}");

  final data = jsonDecode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    final prefs = await SharedPreferences.getInstance();

    // ✅ SAFE TOKEN HANDLING
    await prefs.setString('token', data['token']);

    Navigator.pushReplacementNamed(context, '/dashboard');
  } else {
    print("Login failed: ${data['message']}");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => login(context),
          child: Text('Login'),
        ),
      ),
    );
  }
}