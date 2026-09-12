import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'splash_page.dart';
import 'pages/signup_page.dart';
import 'pages/verify_email_pending_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';
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
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
         '/verify-email-pending': (context) => const VerifyEmailPendingPage(),
         '/forgot-password': (context) => const ForgotPasswordPage(),
         '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
 const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

 Future<void> login() async {
  try {
    final url = Uri.parse('http://10.0.2.2:3000/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "email": emailController.text.trim(),
        "password": passwordController.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        data['token'],
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message']?.toString() ??
                'Login failed',
          ),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to connect to the server',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
             padding: const EdgeInsets.all(20),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                  ),
               ),

               const SizedBox(height: 16),

               TextField(
                 controller: passwordController,
                 obscureText: true,
                 decoration: const InputDecoration(
                   labelText: "Password",
                  ),
                ),

                TextButton(
                 onPressed: () {
                   Navigator.pushNamed(
                    context,
                    '/forgot-password',
                   );
                 },
                 child: const Text(
                 'Forgot Password?',
                 ),
          ),

               const SizedBox(height: 24),

               ElevatedButton(
                 onPressed: login,
                 child: const Text("Login"),
               ),
               const SizedBox(height: 16),
               TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/signup',
                  );
                },
                child: const Text(
                  "Create a new account",
                ),
               ),
               TextButton(
                 onPressed: () {
                   final email = emailController.text.trim();

                   if (email.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(
                         content: Text('Enter your email first'),
                  ),
               ); 
               return;
              }

              Navigator.pushNamed(
                context,
                '/verify-email-pending',
                arguments: email,
               );
             },
           child: const Text(
             'Resend verification email',
           ),
         ),
             ],
           ),
         )
    );
  }
}