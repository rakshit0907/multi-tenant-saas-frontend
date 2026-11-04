import 'package:flutter/material.dart';
import '../models/workspace_member.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MembersPage extends StatefulWidget {
  final String projectId;

  const MembersPage({super.key, required this.projectId});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List members = [];
  List<WorkspaceMember> organizationUsers = [];
  bool loading = true;

  String? myRole;

  @override
  void initState() {
    super.initState();
    loadMembers();
    loadOrganizationUsers();
  }

  Future<void> loadOrganizationUsers() async {
    try {
      final users = await ApiService.getOrganizationUsers();

      debugPrint("ORGANIZATION USERS: $users");
      setState(() {
        organizationUsers = users;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadMembers() async {
    try {
      debugPrint("Project ID: ${widget.projectId}");

      final role = await ApiService.getMyProjectRole(widget.projectId);

      final data = await ApiService.getProjectMembers(widget.projectId);
      debugPrint("Members  API Response: $data");
      debugPrint("Count: ${data.length}");

      setState(() {
        myRole = role;
        members = data;
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadMyRole() async {
    try {
      final role = await ApiService.getMyProjectRole(widget.projectId);

      if (!mounted) return;

      setState(() {
        myRole = role;
      });
    } catch (e) {
      debugPrint('LOAD ROLE ERROR: $e');
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      await ApiService.removeProjectMember(widget.projectId, userId);

      await loadMembers();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> showAddMemberDialog() async {
    String? selectedUserId;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableUsers = organizationUsers
                .where(
                  (user) =>
                      !members.any((member) => member["user"]["id"] == user.id),
                )
                .toList();

            return AlertDialog(
              title: const Text("Invite Member"),

              content: availableUsers.isEmpty
                  ? const Text("No users available to invite.")
                  : DropdownButtonFormField<String>(
                      initialValue: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: "Select user",
                        border: OutlineInputBorder(),
                      ),

                      items: availableUsers
                          .map(
                            (user) => DropdownMenuItem<String>(
                              value: user.id,
                              child: Text("${user.name} (${user.email})"),
                            ),
                          )
                          .toList(),

                      onChanged: (value) {
                        setDialogState(() {
                          selectedUserId = value;
                        });
                      },
                    ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: selectedUserId == null
                      ? null
                      : () async {
                          try {
                            await ApiService.createInvitation(
                              widget.projectId,
                              selectedUserId!,
                            );

                            if (!context.mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Invitation sent successfully"),
                              ),
                            );
                          } catch (e) {
                            debugPrint("INVITATION ERROR: $e");

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to send invitation"),
                              ),
                            );
                          }
                        },
                  child: const Text("Invite"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${members.length} ${members.length == 1 ? 'member' : 'members'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (myRole == 'OWNER')
            IconButton(
              tooltip: 'Invite member',
              icon: const Icon(Icons.person_add_alt_1_rounded),
              color: AppColors.accessiblePrimary,
              onPressed: showAddMemberDialog,
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accessiblePrimary,
              ),
            )
          : members.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.group_off_rounded,
                        size: 36,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No members yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Project members will appear here once they’re added.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (myRole == 'OWNER') ...[
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedButton.icon(
                        onPressed: showAddMemberDialog,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Invite member'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.background,
                      foregroundColor: AppColors.accessiblePrimary,
                      child: Text(
                        (member['user']['name'] as String)
                            .trim()
                            .characters
                            .first
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(
                      member['user']['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(
                        member['user']['email'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: member['role'] == 'OWNER'
                                ? AppColors.accent.withValues(alpha: 0.20)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            member['role'],
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (myRole == 'OWNER' && member['role'] != 'OWNER')
                          IconButton(
                            tooltip: 'Remove member',
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: AppColors.error,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Remove Member'),
                                  content: Text(
                                    'Remove ${member['user']['name']} from this project?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await removeMember(member['user']['id']);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
