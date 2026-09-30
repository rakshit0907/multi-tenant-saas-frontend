import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WorkspaceInvitePage extends StatefulWidget {
  const WorkspaceInvitePage({super.key});

  @override
  State<WorkspaceInvitePage> createState() => _WorkspaceInvitePageState();
}

class _WorkspaceInvitePageState extends State<WorkspaceInvitePage> {
  bool accepting = false;
  String? errorMessage;

  Future<void> acceptInvite(String token) async {
    setState(() {
      accepting = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.acceptWorkspaceInviteExisting(token);

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

  @override
  Widget build(BuildContext context) {
    final token = ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Workspace Invitation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_add_outlined, size: 64),
              const SizedBox(height: 16),

              const Text(
                'You have been invited to a workspace',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 24),

              if (token == null || token.isEmpty)
                const Text('Invalid invitation link')
              else
                ElevatedButton(
                  onPressed: accepting ? null : () => acceptInvite(token),
                  child: accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Accept Invitation'),
                ),

              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
