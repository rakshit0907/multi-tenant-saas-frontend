import 'package:flutter/material.dart';

import '../services/api_service.dart';

class VerifyEmailPendingPage extends StatefulWidget {
  const VerifyEmailPendingPage({super.key});

  @override
  State<VerifyEmailPendingPage> createState() =>
      _VerifyEmailPendingPageState();
}

class _VerifyEmailPendingPageState
    extends State<VerifyEmailPendingPage> {
  bool _resending = false;

  Future<void> _resendEmail(String email) async {
    setState(() {
      _resending = true;
    });

    try {
      await ApiService.resendVerificationEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        ModalRoute.of(context)?.settings.arguments as String?;

    if (email == null || email.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Email address not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
              ),
              const SizedBox(height: 24),
              const Text(
                'Check your email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We sent a verification link to:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Open the link in the email to verify your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _resending
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: () => _resendEmail(email),
                      child: const Text(
                        'Resend verification email',
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}