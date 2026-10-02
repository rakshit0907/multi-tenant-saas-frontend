import 'package:flutter/material.dart';

import '../models/workspace_member.dart';
import '../services/api_service.dart';

class WorkspaceMembersPage extends StatefulWidget {
  final String workspaceRole;

  const WorkspaceMembersPage({super.key, required this.workspaceRole});

  @override
  State<WorkspaceMembersPage> createState() => _WorkspaceMembersPageState();
}

class _WorkspaceMembersPageState extends State<WorkspaceMembersPage> {
  List<WorkspaceMember> members = [];

  bool loading = true;
  String? errorMessage;

  bool get canInvite =>
      widget.workspaceRole == 'OWNER' || widget.workspaceRole == 'ADMIN';

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      final data = await ApiService.getOrganizationUsers();

      if (!mounted) return;

      setState(() {
        members = data;
        loading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> changeMemberRole(WorkspaceMember member, String newRole) async {
    try {
      await ApiService.updateWorkspaceMemberRole(member.id, newRole);

      await loadMembers();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${member.name} is now $newRole')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> removeMember(WorkspaceMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Member'),
          content: Text('Remove ${member.name} from this workspace?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.removeWorkspaceMember(member.id);

      await loadMembers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} removed from workspace')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String formatJoinedDate(DateTime? date) {
    if (date == null) {
      return 'Join date unavailable';
    }

    final localDate = date.toLocal();

    return 'Joined ${localDate.day}/${localDate.month}/${localDate.year}';
  }

  Color roleColor(BuildContext context, String role) {
    final scheme = Theme.of(context).colorScheme;

    switch (role) {
      case 'OWNER':
        return scheme.primary;
      case 'ADMIN':
        return scheme.secondary;
      case 'MEMBER':
        return scheme.tertiary;
      default:
        return scheme.outline;
    }
  }

  Widget _buildRoleAction(BuildContext context, WorkspaceMember member) {
    final isOwner = member.role == 'OWNER';

    final canManage =
        widget.workspaceRole == 'OWNER' || widget.workspaceRole == 'ADMIN';

    if (!canManage || isOwner) {
      return _buildRoleBadge(context, member.role);
    }

    List<String> availableRoles;

    if (widget.workspaceRole == 'OWNER') {
      availableRoles = ['ADMIN', 'MEMBER', 'GUEST'];
    } else {
      // ADMIN cannot promote to ADMIN
      // and cannot manage another ADMIN.
      if (member.role == 'ADMIN') {
        return _buildRoleBadge(context, member.role);
      }

      availableRoles = ['MEMBER', 'GUEST'];
    }

    return PopupMenuButton<String>(
      tooltip: 'Change role',
      onSelected: (newRole) {
        if (newRole == member.role) return;

        changeMemberRole(member, newRole);
      },
      itemBuilder: (context) {
        return availableRoles.map((role) {
          return PopupMenuItem<String>(
            value: role,
            child: Row(
              children: [
                if (role == member.role)
                  const Icon(Icons.check, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(role),
              ],
            ),
          );
        }).toList();
      },
      child: _buildRoleBadge(context, member.role),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor(context, role)),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: roleColor(context, role),
        ),
      ),
    );
  }

  Widget _buildMemberActions(BuildContext context, WorkspaceMember member) {
    final canManage =
        widget.workspaceRole == 'OWNER' || widget.workspaceRole == 'ADMIN';

    final canRemove =
        canManage &&
        member.role != 'OWNER' &&
        !(widget.workspaceRole == 'ADMIN' && member.role == 'ADMIN');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRoleAction(context, member),

        if (canRemove) ...[
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Remove member',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              removeMember(member);
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace Members'),
        actions: [
          if (canInvite)
            IconButton(
              tooltip: 'Invite member',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Use the dashboard invite button for now'),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadMembers,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 56),
                        const SizedBox(height: 16),
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadMembers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : members.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Column(
                    children: [
                      Icon(Icons.group_outlined, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'No workspace members found',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = members[index];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(member.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(member.email),
                          const SizedBox(height: 4),
                          Text(formatJoinedDate(member.joinedAt)),
                        ],
                      ),
                      trailing: _buildMemberActions(context, member),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
