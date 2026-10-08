import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class WorkspaceInvitePage extends StatefulWidget {
  const WorkspaceInvitePage({super.key});

  @override
  State<WorkspaceInvitePage> createState() => _WorkspaceInvitePageState();
}

class _WorkspaceInvitePageState extends State<WorkspaceInvitePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool checkingSession = true;
  bool isLoggedIn = false;
  bool accepting = false;
  bool accountCreated = false;
  bool obscurePassword = true;

  String? errorMessage;
  String? createdWorkspaceName;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    setState(() {
      isLoggedIn = token != null && token.isNotEmpty;
      checkingSession = false;
    });
  }

  Future<void> acceptExistingUserInvite(String token) async {
    setState(() {
      accepting = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.acceptWorkspaceInviteExisting(token);

      final newToken = result['token']?.toString();

      if (newToken != null && newToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', newToken);
      }

      if (!mounted) return;

      final workspace = result['workspace'];

      final workspaceName = workspace is Map
          ? workspace['name']?.toString()
          : null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            workspaceName != null
                ? 'Joined $workspaceName'
                : 'Workspace invitation accepted',
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        accepting = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> acceptNewUserInvite(String token) async {
    final name = nameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty) {
      setState(() {
        errorMessage = 'Name is required';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        errorMessage = 'Password is required';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      accepting = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.acceptWorkspaceInviteNewUser(
        inviteToken: token,
        name: name,
        password: password,
      );

      if (!mounted) return;

      final workspace = result['workspace'];

      setState(() {
        accepting = false;
        accountCreated = true;

        createdWorkspaceName = workspace is Map
            ? workspace['name']?.toString()
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        accepting = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Workspace Invitation')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: checkingSession
                ? const Center(child: CircularProgressIndicator())
                : token == null || token.isEmpty
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Invalid invitation link',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : accountCreated
                ? _buildSuccessView()
                : isLoggedIn
                ? _buildExistingUserView(token)
                : _buildNewUserView(token),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingUserView(String token) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.group_add_outlined, size: 64),

        const SizedBox(height: 16),

        const Text(
          'You have been invited to a workspace',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          'Accept the invitation to add this workspace to your account.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: accepting ? null : () => acceptExistingUserInvite(token),
            child: accepting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Accept Invitation'),
          ),
        ),

        _buildError(),
      ],
    );
  }

  Widget _buildNewUserView(String token) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_add_alt_1_outlined, size: 64),

        const SizedBox(height: 16),

        const Text(
          'Join the workspace',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        const Text(
          'Create your Worqly account to accept this invitation.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        TextField(
          controller: nameController,
          enabled: !accepting,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: passwordController,
          enabled: !accepting,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextField(
          controller: confirmPasswordController,
          enabled: !accepting,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: accepting ? null : (_) => acceptNewUserInvite(token),
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            border: OutlineInputBorder(),
          ),
        ),

        _buildError(),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: accepting ? null : () => acceptNewUserInvite(token),
            child: accepting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Account & Join'),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: accepting
              ? null
              : () {
                  Navigator.pushNamed(context, '/login', arguments: token);
                },
          child: const Text('Already have an account? Log in'),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 72),

        const SizedBox(height: 20),

        const Text(
          'Account created!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        Text(
          createdWorkspaceName != null
              ? 'You joined $createdWorkspaceName.'
              : 'Your workspace invitation has been accepted.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'Check your email and verify your account before logging in.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Go to Login'),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    if (errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        errorMessage!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
