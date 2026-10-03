import 'package:flutter/material.dart';

import '../models/workspace.dart';
import '../services/api_service.dart';

class WorkspaceSettingsPage extends StatefulWidget {
  final Workspace workspace;
  final String workspaceRole;

  const WorkspaceSettingsPage({
    super.key,
    required this.workspace,
    required this.workspaceRole,
  });

  @override
  State<WorkspaceSettingsPage> createState() => _WorkspaceSettingsPageState();
}

class _WorkspaceSettingsPageState extends State<WorkspaceSettingsPage> {
  late final TextEditingController nameController;

  bool saving = false;
  String? errorMessage;

  bool get isOwner => widget.workspaceRole == 'OWNER';

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.workspace.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveWorkspace() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        errorMessage = 'Workspace name is required';
      });

      return;
    }

    if (name == widget.workspace.name) {
      setState(() {
        errorMessage = 'Enter a different workspace name';
      });

      return;
    }

    setState(() {
      saving = true;
      errorMessage = null;
    });

    try {
      final updatedWorkspace = await ApiService.updateWorkspaceName(name);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workspace renamed successfully')),
      );

      Navigator.pop(context, updatedWorkspace);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workspace Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Workspace', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 16),

          TextField(
            controller: nameController,
            enabled: isOwner && !saving,
            decoration: InputDecoration(
              labelText: 'Workspace name',
              border: const OutlineInputBorder(),
              helperText: isOwner
                  ? 'Only the workspace owner can rename this workspace'
                  : 'Only the workspace owner can edit this setting',
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],

          const SizedBox(height: 20),

          if (isOwner)
            ElevatedButton(
              onPressed: saving ? null : saveWorkspace,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),

          const SizedBox(height: 24),

          const Divider(),

          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Your workspace role'),
            subtitle: Text(widget.workspaceRole),
          ),
        ],
      ),
    );
  }
}
