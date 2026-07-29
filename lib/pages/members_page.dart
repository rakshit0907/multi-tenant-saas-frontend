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

  String myRole = "";

  @override
  void initState() {
    super.initState();
    loadMembers();
    loadMyRole();
  }

  Future<void> loadMembers() async {
    try {

      debugPrint("Project ID: ${widget.projectId}");

      final data =
          await ApiService.getProjectMembers(
        widget.projectId,
      );
      debugPrint("Members  API Response: $data");
      debugPrint("Count: ${data.length}");

      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Members"),
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
                     trailing: myRole == "Owner"
                       ? Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text(member["role"]),
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
                     : Text(member["role"]),
                   );
                 },
               ),
             );
            }
          }