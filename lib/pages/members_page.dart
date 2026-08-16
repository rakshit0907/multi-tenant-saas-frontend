import 'package:flutter/material.dart';
import '../models/user_model.dart';
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
  List<UserModel> organizationUsers = [];
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
      final users = 
          await ApiService.getOrganizationUsers();

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
    String? selectedUserId;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final availableUsers = organizationUsers
                .where(
                  (user) => !members.any(
                    (member) =>
                        member["user"]["id"] == user.id,
                  ),
                )
                .toList();

            return AlertDialog(
              title: const Text("Invite Member"),

              content: availableUsers.isEmpty
                  ? const Text(
                     "No users available to invite.",
                    )
                  : DropdownButtonFormField<String>(
                      value: selectedUserId,
                      decoration: const InputDecoration(
                        labelText: "Select user",
                        border: OutlineInputBorder(),
                      ),

                      items: availableUsers
                          .map(
                            (user) => DropdownMenuItem<String>(
                              value: user.id,
                              child: Text(
                                "${user.name} (${user.email})",
                              ),
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

                             ScaffoldMessenger.of(context)
                                 .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Invitation sent successfully",
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint(
                              "INVITATION ERROR: $e",
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Failed to send invitation",
                                ),
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                            ),
                           ], 
                     
                          ),
                        );
                      },
                    ),
                  );
                }
              }