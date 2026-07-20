import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'models/project.dart';
import 'services/api_service.dart';
import 'pages/tasks_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userId = "";
  String tenantId = "";
  String role = "";

  List<Project> projects = [];
  bool loading = true;

  final TextEditingController projectController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadProjects();
  }
  Future<void> deleteProject(String projectId) async {
    try {
      await ApiService.deleteProject(projectId);
      setState(() {
        loading = true;
      });
      await loadProjects();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  Future<void> createProject() async {
    try {
      await ApiService.createProject(
        projectController.text,
      );

      projectController.clear();

      if (!mounted) return;

      Navigator.pop(context);

      setState(() {
        loading = true;
      });

      await loadProjects();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null) return;

    final decodedToken = JwtDecoder.decode(token);

    setState(() {
      userId = decodedToken['userId'] ?? '';
      tenantId = decodedToken['tenantId'] ?? '';
      role = decodedToken['role'] ?? '';
    });
  }

  Future<void> loadProjects() async {
    try {
      final data = await ApiService.getProjects();

      setState(() {
        projects = data
            .map<Project>((e) => Project.fromJson(e))
            .toList();

        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text(
                  "Create Project",
                ),
                content: TextField(
                  controller: projectController,
                  decoration: const InputDecoration(
                    hintText: "Project name",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel",
                    ),
                  ),
                  ElevatedButton(
                    onPressed: createProject,
                    child: const Text(
                      "Create",
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                const SizedBox(height: 20),

                Text("Role: $role"),
                Text("Tenant: $tenantId"),

                const Divider(),

                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];

                      return Card(
                        child: ListTile(
                          title: Text(project.name),
                          subtitle: Text(project.id),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TasksPage(
                                  projectId: project.id,
                                  projectName: project.name,
                                ),
                              ),
                            );
                          },

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Delete Project",
                                    ),
                                    content: Text(
                                      "Delete '${project.name}'?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            dialogContext,
                                          );
                                        },
                                        child: const Text(
                                          "Cancel",
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(
                                            dialogContext,
                                          );

                                          await deleteProject(
                                            project.id,
                                          );
                                        },
                                        child: const Text(
                                          "Delete",
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}