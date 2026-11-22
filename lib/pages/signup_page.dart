import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final tenantController = TextEditingController();

  bool loading = false;

  Future<void> signup() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "name": nameController.text.trim(),
              "email": emailController.text.trim(),
              "password": passwordController.text,
              "tenantName": tenantController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/verify-email-pending',
          arguments: emailController.text.trim(),
        );
      } else {
        if (!mounted) return;
        final message = data["message"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message is List ? message.join(', ') : message.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to connect to the server')),
      );
    }
    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: tenantController,
              decoration: const InputDecoration(labelText: "Organization Name"),
            ),

            const SizedBox(height: 24),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: signup,
                    child: const Text("Create Account"),
                  ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
