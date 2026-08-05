import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'kanban_page.dart';
import 'members_page.dart';

class ProjectDashboardPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDashboardPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });
  @override
  State<ProjectDashboardPage> createState() =>
      _ProjectDashboardPageState();
 }    

  class _ProjectDashboardPageState
    extends State<ProjectDashboardPage> {

  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final data = await ApiService.getTaskStats(
        widget.projectId,
      );

      setState(() {
        stats = data;
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
        title: Text(widget.projectName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                     )
                     : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Project Overview",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                             child: _statCard(
                               "Total",
                               stats?["total"] ?? 0,
                               Colors.blue,
                             ),
                           ),
                           const SizedBox(width: 12),
                           Expanded(
                            child: _statCard(
                              "Done",
                              stats?["done"] ?? 0,
                              Colors.green,
                            ),
                       ),
                     ],
                   ),

                   const SizedBox(height: 12),

                   Row(
                     children: [
                       Expanded(
                         child: _statCard(
                           "In Progress",
                           stats?["inProgress"] ?? 0,
                           Colors.orange,
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: _statCard(
                           "To Do",
                            stats?["todo"] ?? 0,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            "High Priority",
                            stats?["highPriority"] ?? 0,
                            Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            "Overdue",
                            stats?["overdue"] ?? 0,
                            Colors.deepOrange,
                          ),
                       ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  LinearProgressIndicator(
                    value: (stats?["completionPercentage"] ?? 0) / 100,
                    minHeight: 10,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Completion: ${stats?["completionPercentage"] ?? 0}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                 ),
              ],
             )
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.view_kanban),
                label: const Text("Open Kanban Board"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KanbanPage(
                        projectId: widget.projectId,
                        projectName: widget.projectName,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.group),
                label: const Text("Project Members"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MembersPage(
                        projectId: widget.projectId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _statCard(
    String title,
    int value,
    Color color,
 ) {
   return Card(
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Column(
         children: [
           Text(
             value.toString(),
             style: TextStyle(
               fontSize: 28,
               fontWeight: FontWeight.bold,
               color: color,
             ),
           ),
           const SizedBox(height: 6),
           Text(title),
         ],
       ),
     ),
   );
 }
}