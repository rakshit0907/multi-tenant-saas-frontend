import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'models/project.dart';
import 'services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadProjects();
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
        projects =
            data.map<Project>((e) => Project.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }


  @override
Widget build(BuildContext context) {
  return Scaffold(
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
                          print(project.id);
                        },
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