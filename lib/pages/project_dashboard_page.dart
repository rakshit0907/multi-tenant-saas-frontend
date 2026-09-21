import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'kanban_page.dart';
import 'members_page.dart';
import 'milestones_page.dart';

class ProjectDashboardPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectDashboardPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  Map<String, dynamic>? dashboard;
  Map<String, dynamic>? stats;

  List<dynamic> activities = [];
  List<dynamic> workload = [];
  List<dynamic> upcomingDeadlines = [];
  List<dynamic> milestones = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final data = await ApiService.getProjectDashboard(widget.projectId);

      if (!mounted) return;

      setState(() {
        dashboard = data;

        stats = Map<String, dynamic>.from(data['tasks'] ?? {});

        activities = List<dynamic>.from(data['recentActivity'] ?? []);

        workload = List<dynamic>.from(data['workload'] ?? []);

        upcomingDeadlines = List<dynamic>.from(data['upcomingDeadlines'] ?? []);
        milestones = List<dynamic>.from(data['milestones'] ?? []);

        loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load project dashboard: $e');

      if (!mounted) return;

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

  String _formatMilestoneDate(dynamic value) {
    if (value == null) return 'No target date';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'No target date';

    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatStatus(dynamic status) {
    switch (status?.toString()) {
      case "PENDING":
        return "Pending";

      case "IN_PROGRESS":
        return "In Progress";

      case "COMPLETED":
        return "Completed";

      default:
        return status?.toString() ?? "Unknown";
    }
  }

  String _formatPriority(dynamic priority) {
    switch (priority?.toString()) {
      case "LOW":
        return "Low";

      case "MEDIUM":
        return "Medium";

      case "HIGH":
        return "High";

      case "URGENT":
        return "Urgent";

      default:
        return priority?.toString() ?? "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
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
                                  null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  "Done",
                                  stats?["completed"] ?? 0,
                                  Colors.green,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => KanbanPage(
                                          projectId: widget.projectId,
                                          projectName: widget.projectName,
                                          initialStatus: "COMPLETED",
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
                                  stats?["inProgress"] ?? 0,
                                  Colors.orange,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => KanbanPage(
                                          projectId: widget.projectId,
                                          projectName: widget.projectName,
                                          initialStatus: "IN_PROGRESS",
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
                                  stats?["pending"] ?? 0,
                                  Colors.red,
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => KanbanPage(
                                          projectId: widget.projectId,
                                          projectName: widget.projectName,
                                          initialStatus: "PENDING",
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
                                  dashboard?["priority"]?["high"] ?? 0,
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
                            value: (stats?["completionPercentage"] ?? 0) / 100,
                            minHeight: 10,
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Completion: ${stats?["completionPercentage"] ?? 0}%",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.groups_outlined),
                              SizedBox(width: 8),
                              Text(
                                "Team Workload",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (workload.isEmpty)
                            const Text(
                              "No project members",
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...workload.map((member) {
                              final total = member["total"] ?? 0;
                              final completed = member["completed"] ?? 0;
                              final inProgress = member["inProgress"] ?? 0;
                              final pending = member["pending"] ?? 0;

                              final progress = total == 0
                                  ? 0.0
                                  : completed / total;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          child: Text(
                                            (member["name"] ?? "?")
                                                .toString()
                                                .substring(0, 1)
                                                .toUpperCase(),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member["name"] ?? "Unknown",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                "$total assigned • "
                                                "$completed done • "
                                                "$inProgress active • "
                                                "$pending pending",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Text(
                                          total == 0
                                              ? "0%"
                                              : "${(progress * 100).round()}%",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.event_outlined),
                              SizedBox(width: 8),
                              Text(
                                "Upcoming Deadlines",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (upcomingDeadlines.isEmpty)
                            const Text(
                              "No upcoming deadlines",
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...upcomingDeadlines.map((task) {
                              final dueDate = DateTime.tryParse(
                                task["dueDate"]?.toString() ?? "",
                              );

                              final assignee = task["assignee"];
                              final priority = _formatPriority(
                                task["priority"],
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.schedule, size: 20),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task["title"] ?? "Untitled task",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            dueDate == null
                                                ? "No due date"
                                                : "${dueDate.day}/${dueDate.month}/${dueDate.year}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),

                                          if (assignee != null)
                                            Text(
                                              "Assigned to ${assignee["name"]}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    Chip(label: Text(priority)),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
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

                  const SizedBox(height: 20),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag_outlined),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Milestones',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MilestonesPage(
                                        projectId: widget.projectId,
                                        projectName: widget.projectName,
                                      ),
                                    ),
                                  );

                                  if (!mounted) return;
                                  await loadStats();
                                },
                                child: const Text('View all'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (milestones.isEmpty)
                            const Text(
                              'No milestones yet',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...milestones.take(3).map((milestone) {
                              final taskCount =
                                  int.tryParse(
                                    milestone['taskCount']?.toString() ?? '',
                                  ) ??
                                  0;

                              final completedTaskCount =
                                  int.tryParse(
                                    milestone['completedTaskCount']
                                            ?.toString() ??
                                        '',
                                  ) ??
                                  0;

                              final progress =
                                  int.tryParse(
                                    milestone['progress']?.toString() ?? '',
                                  ) ??
                                  0;

                              final progressValue =
                                  progress.clamp(0, 100) / 100.0;

                              final completed =
                                  milestone['status']?.toString() ==
                                  'COMPLETED';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            milestone['name']?.toString() ??
                                                'Unnamed milestone',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            completed ? 'Completed' : 'Active',
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      _formatMilestoneDate(
                                        milestone['targetDate'],
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$completedTaskCount of '
                                            '$taskCount tasks completed',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$progress%',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    LinearProgressIndicator(
                                      value: progressValue,
                                      minHeight: 7,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
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
                            builder: (_) =>
                                MembersPage(projectId: widget.projectId),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Project Milestones'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MilestonesPage(
                              projectId: widget.projectId,
                              projectName: widget.projectName,
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
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...activities.map((activity) {
                              final user =
                                  activity["user"]?["name"] ?? "Unknown user";

                              final action = activity["action"] ?? "UNKNOWN";

                              final task = activity["task"]?["title"];

                              String message;

                              switch (action) {
                                case "MEMBER_ADDED":
                                  final name =
                                      activity["metadata"]?["addedUserName"] ??
                                      "a member";
                                  message = "$user added $name to the project";
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
                                  message = "$user created task ${task ?? ""}";
                                  break;

                                case "TASK_UPDATED":
                                  message = "$user updated task ${task ?? ""}";
                                  break;

                                case "TASK_STATUS_CHANGED":
                                  final oldStatus =
                                      activity["metadata"]?["oldStatus"] ??
                                      "Unknown";

                                  final newStatus =
                                      activity["metadata"]?["newStatus"] ??
                                      "Unknown";

                                  final taskName = task ?? "a task";

                                  message =
                                      "$user changed \"$taskName\" status from "
                                      "${_formatStatus(oldStatus)} to "
                                      "${_formatStatus(newStatus)}";
                                  break;

                                case "TASK_PRIORITY_CHANGED":
                                  final oldPriority =
                                      activity["metadata"]?["oldPriority"] ??
                                      "Unknown";

                                  final newPriority =
                                      activity["metadata"]?["newPriority"] ??
                                      "Unknown";

                                  final taskName = task ?? "a task";

                                  message =
                                      "$user changed \"$taskName\" priority from "
                                      "${_formatPriority(oldPriority)} to "
                                      "${_formatPriority(newPriority)}";
                                  break;
                                case "TASK_DELETED":
                                  message = "$user deleted task ${task ?? ""}";
                                  break;

                                default:
                                  message = "$user performed $action";
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 18,
                                      child: Icon(Icons.history, size: 18),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            message,
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            _formatActivityTime(
                                              activity["createdAt"],
                                            ),
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
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, int value, Color color, VoidCallback? onTap) {
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
