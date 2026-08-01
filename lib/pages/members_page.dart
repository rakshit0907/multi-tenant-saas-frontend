import 'package:flutter/material.dart';

import '../services/api_service.dart';

class MembersPage extends StatefulWidget {
  final String projectId;

  const MembersPage({
    super.key,
    required this.projectId,
  });

  @override
  State<MembersPage> createState() => _MembersPageState();
}
class _MembersPageState extends State<MembersPage> {
  List members = [];
  bool loading = true;

  String? myRole;
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMembers();
    loadMyRole();
  }

  Future<void> loadMembers() async {
    try {

      debugPrint("Project ID: ${widget.projectId}");

      final role =
          await ApiService.getMyProjectRole(
        widget.projectId,
      );

      final data = await ApiService.getProjectMembers(
        widget.projectId,
      );
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
      myRole = await ApiService.getMyProjectRole(
        widget.projectId,
      );

      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> removeMember(String userId) async {
    try {
      await ApiService.removeProjectMember(
        widget.projectId,
        userId,
      );

      await loadMembers();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  
  Future<void> showAddMemberDialog() async {
    emailController.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: "Enter member email",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.addMember(
                  widget.projectId,
                  emailController.text.trim(),
                );

                if (!mounted) return;

                Navigator.pop(context);

                await loadMembers();
              } catch (e) {
                debugPrint(e.toString());
             }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Members"),
        actions: [
          if (myRole == "OWNER")
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: showAddMemberDialog,
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : members.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                       Icons.group_off,
                       size: 60,
                       color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No members added yet",
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
             : ListView.builder(
                 itemCount: members.length,
                 itemBuilder: (context, index) {
                   final member = members[index];

                   return ListTile(
                     leading: const CircleAvatar(
                       child: Icon(Icons.person),
                     ),
                     title: Text(
                       member["user"]["name"],
                     ),
                     subtitle: Text(
                       member["user"]["email"],
                     ),
                     trailing: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(member["role"]),

                         if (myRole == "OWNER" && member["role"] != "OWNER")
                           const SizedBox(width: 8),
                           IconButton(
                             icon: const Icon(
                               Icons.delete,
                               color: Colors.red,
                             ),
                             onPressed: () async {
                             final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Remove Member"),
                                content: Text(
                                  "Remove ${member["user"]["name"]} from this project?",
                                ),
                                actions: [
                                 TextButton(
                                   onPressed: () =>
                                       Navigator.pop(context, false),
                                   child: const Text("Cancel"),
                                 ),
                                 ElevatedButton(
                                   onPressed: () =>
                                       Navigator.pop(context, true),
                                   child: const Text("Remove"),
                                 ),
                               ],
                             ),
                           );

                           if (confirm == true) {
                             await removeMember(
                               member["user"]["id"],
                              );
                             }
                           },
                         ),
                       ],
                     )
                   );
                 },
               ),
             );
            }
          }