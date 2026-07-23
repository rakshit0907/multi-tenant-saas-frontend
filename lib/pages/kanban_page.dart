import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class KanbanPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const KanbanPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends State<KanbanPage> {
  List<Task> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final data = await ApiService.getTasks(widget.projectId);

      setState(() {
        tasks = data.map<Task>((e) => Task.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        loading = false;
      });
    }
  }
  Future<void> moveTask(
  Task task,
  String newColumn,
) async {

  String status;

  switch (newColumn) {
    case "Pending":
      status = "PENDING";
      break;

    case "In Progress":
      status = "IN_PROGRESS";
      break;

    case "Completed":
      status = "COMPLETED";
      break;

    default:
      status = "PENDING";
  }

  try {
    await ApiService.updateTaskStatus(
      task.id,
      status,
    );

    await loadTasks();
  } catch (e) {
    debugPrint(e.toString());
  }
}

  @override
Widget build(BuildContext context) {
  final pendingTasks =
      tasks.where((t) => t.status == "PENDING").toList();

  final inProgressTasks =
      tasks.where((t) => t.status == "IN_PROGRESS").toList();

  final completedTasks =
      tasks.where((t) => t.status == "COMPLETED").toList();

  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        bottom: const TabBar(
          tabs: [
            Tab(text: "Pending"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TabBarView(
              children: [
                KanbanColumn(
                  tasks: pendingTasks,
                  onMove: moveTask,
                ),
                KanbanColumn(
                  tasks: inProgressTasks,
                  onMove: moveTask,
                ),
                KanbanColumn(
                  tasks: completedTasks,
                  onMove: moveTask,
                ),
              ],
            ),
    ),
  );
}
}

class KanbanColumn extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task, String) onMove;

  const KanbanColumn({
    super.key,
    required this.tasks,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text("No Tasks"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(task.priority),
                 if (task.dueDate != null)
                   Text(
                    "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                    style: const TextStyle(fontSize: 12),
                   ),
                 ],
               ),
            trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          onMove(task, value);
                        },
                        itemBuilder: (_) => [
                         if (task.status != "PENDING")
                           const PopupMenuItem(
                              value: "Pending",
                              child: Text("Move to Pending"),
                            ),

                           if (task.status != "IN_PROGRESS")
                             const PopupMenuItem(
                               value: "In Progress",
                               child: Text("Move to In Progress"),
                              ),

                           if (task.status != "COMPLETED")
                             const PopupMenuItem(
                               value: "Completed",
                               child: Text("Move to Completed"),
                              ),
                            ],
                          ),
          ),
        );
      },
    );
  }
}