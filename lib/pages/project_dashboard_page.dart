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
  List<dynamic> activities = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final data =
          await ApiService.getTaskStats(widget.projectId);

       final activityData =
          await ApiService.getProjectActivity(widget.projectId);

       debugPrint("PROJECT ACTIVITY: $activityData");    

      setState(() {
        stats = data;
        activities = activityData;
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        loading = false;
      });
    }
  }
  
  String _formatActivityTime(dynamic createdAt) {
    if (createdAt == null) {
       return '';
    }

    final date = DateTime.tryParse(createdAt.toString());

    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date.toLocal());

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
       return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }

    if (difference.inHours < 24) {
       return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays == 1) {
       return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

     return '${date.day}/${date.month}/${date.year}';
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Project Overview",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
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
                                  null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  "Done",
                                  stats?["done"] ?? 0,
                                  Colors.green,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            KanbanPage(
                                          projectId:
                                              widget.projectId,
                                          projectName:
                                              widget.projectName,
                                          initialStatus:
                                              "COMPLETED",
                                        ),
                                      ),
                                    );
                                  },
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
                                  stats?["inProgress"] ??
                                      0,
                                  Colors.orange,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            KanbanPage(
                                          projectId:
                                              widget.projectId,
                                          projectName:
                                              widget.projectName,
                                          initialStatus:
                                              "IN_PROGRESS",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  "To Do",
                                  stats?["todo"] ?? 0,
                                  Colors.red,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            KanbanPage(
                                          projectId:
                                              widget.projectId,
                                          projectName:
                                              widget.projectName,
                                          initialStatus:
                                              "PENDING",
                                        ),
                                      ),
                                    );
                                  },
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
                                  stats?["highPriority"] ??
                                      0,
                                  Colors.purple,
                                  null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  "Overdue",
                                  stats?["overdue"] ?? 0,
                                  Colors.deepOrange,
                                  null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          LinearProgressIndicator(
                            value: (stats?[
                                            "completionPercentage"] ??
                                        0) /
                                    100,
                            minHeight: 10,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Completion: ${stats?["completionPercentage"] ?? 0}%",
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                          Icons.view_kanban),
                      label: const Text(
                          "Open Kanban Board"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KanbanPage(
                              projectId:
                                  widget.projectId,
                              projectName:
                                  widget.projectName,
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
                      icon:
                          const Icon(Icons.group),
                      label: const Text(
                          "Project Members"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MembersPage(
                              projectId:
                                  widget.projectId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recent Activity",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          if (activities.isEmpty)
                            const Text(
                              "No recent activity",
                              style: TextStyle(
                                color: Colors.grey,
                            ),
                          )
                        else
                         ...activities.map(
                           (activity) {
                              final user =
                                   activity["user"]?["name"] ?? "Unknown user";

                              final action =
                                   activity["action"] ?? "UNKNOWN";

                              final task =
                                    activity["task"]?["title"];

                              String message;

                              switch (action) {
                                case "MEMBER_ADDED":
                               final name =
                      activity["metadata"]?["addedUserName"] ??
                          "a member";
                  message =
                      "$user added $name to the project";
                  break;

                case "MEMBER_REMOVED":
                  final name =
                      activity["metadata"]?["removedUserName"] ??
                          "a member";
                  message =
                      "$user removed $name from the project";
                  break;

                case "MEMBER_ROLE_CHANGED":
                  final name =
                      activity["metadata"]?["targetUserName"] ??
                          "a member";
                  final newRole =
                      activity["metadata"]?["newRole"] ??
                          "a new role";
                  message =
                      "$user changed $name's role to $newRole";
                  break;

                case "TASK_CREATED":
                  message =
                      "$user created task ${task ?? ""}";
                  break;

                case "TASK_UPDATED":
                  message =
                      "$user updated task ${task ?? ""}";
                  break;

                case "TASK_DELETED":
                  message =
                      "$user deleted task ${task ?? ""}";
                  break;

                default:
                  message =
                      "$user performed $action";
              }

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.history,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _formatActivityTime(activity["createdAt"]),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    ),
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
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
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
      ),
    );
  }
}