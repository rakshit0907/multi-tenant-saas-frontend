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

  @override
  void initState() {
    super.initState();
    loadMembers();
  }

  Future<void> loadMembers() async {
    try {
      final data =
          await ApiService.getProjectMembers(
        widget.projectId,
      );

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
                  trailing: Text(
                    member["role"],
                  ),
                );
              },
            ),
    );
  }
}