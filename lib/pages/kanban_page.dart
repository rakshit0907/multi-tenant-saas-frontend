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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.projectName),
            Text(
              "${tasks.length} Tasks",
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          tabs: [
            Tab(text: "Pending (${pendingTasks.length})"),
            Tab(text: "In Progress (${inProgressTasks.length})"),
            Tab(text: "Completed (${completedTasks.length})"),
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
                if (task.description != null &&
                    task.description!.isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 6),
                     child: Text(
                       task.description!,
                       maxLines: 2,
                       overflow: TextOverflow.ellipsis,
                       style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                   Align(
                     alignment: Alignment.centerLeft,
                     child: Container(
                       margin: const EdgeInsets.only(top: 4),
                       padding: const EdgeInsets.symmetric(
                         horizontal: 8,
                         vertical: 3,
                       ),
                       decoration: BoxDecoration(
                       color: task.priority == "HIGH"
                           ? Colors.red.shade100
                           : task.priority == "MEDIUM"
                               ? Colors.orange.shade100
                               : Colors.green.shade100,
                       borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.priority,
                         style: TextStyle(
                           fontSize: 11,
                           fontWeight: FontWeight.bold,
                           color: task.priority == "HIGH"
                               ? Colors.red
                               : task.priority == "MEDIUM"
                                   ? Colors.orange
                                   : Colors.green,
                           ),
                          ),
                        ),
                      ),
                 const SizedBox(height: 6),
                 if (task.dueDate != null)
                   Text(
                    "${task.dueDate!.day.toString().padLeft(2,'0')}/"
                    "${task.dueDate!.month.toString().padLeft(2,'0')}/"
                    "${task.dueDate!.year}",
                    style: TextStyle(
                      fontSize: 12,
                      color: task.dueDate!.isBefore(DateTime.now()) &&
                              task.status != "COMPLETED"
                           ? Colors.red
                           : Colors.grey,
                      fontWeight: task.dueDate!.isBefore(DateTime.now()) &&
                            task.status != "COMPLETED"
                         ? FontWeight.bold
                         : FontWeight.normal,   
                   ),
                   ), 

                   const SizedBox(height: 6),

                   Container(
                     padding: const EdgeInsets.symmetric(
                       horizontal: 8,
                       vertical: 3,
                     ),
                     decoration: BoxDecoration(
                       color: task.status == "PENDING"
                           ? Colors.orange.shade100
                           : task.status == "IN_PROGRESS"
                               ? Colors.blue.shade100
                               : Colors.green.shade100,
                       borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task.status.replaceAll("_", " "),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: task.status == "PENDING"
                              ? Colors.orange
                              : task.status == "IN_PROGRESS"
                                  ? Colors.blue
                                  : Colors.green,
                          ),
                         ),
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