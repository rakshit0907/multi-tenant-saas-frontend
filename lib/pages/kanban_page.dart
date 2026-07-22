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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Row(
              children: [
                Expanded(
                  child: KanbanColumn(
                    title: "Pending",
                    color: Colors.orange,
                    tasks: pendingTasks,
                    onDrop: moveTask,
                  ),
                ),
                Expanded(
                  child: KanbanColumn(
                    title: "In Progress",
                    color: Colors.blue,
                    tasks: inProgressTasks,
                    onDrop: moveTask,
                  ),
                ),
                Expanded(
                  child: KanbanColumn(
                    title: "Completed",
                    color: Colors.green,
                    tasks: completedTasks,
                    onDrop: moveTask,
                  ),
                ),
              ],
            ),
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final Function(Task task, String newStatus) onDrop;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.color,
    required this.tasks,
    required this.onDrop,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onAcceptWithDetails: (details) {
        onDrop(details.data, title);
      },

      builder: (context, candidateData, rejectedData) {
        return Container(

           
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                return Draggable<Task>(
                  data: task,

                  feedback: Material(
                    elevation: 8,
                    child: Card(
                      child: Padding(
                       padding: const EdgeInsets.all(12),
                       child: Text(task.title),
                      ),
                    ),
                  ),

                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(task.title),
                      ),
                     ),
                    ),

                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(task.title),
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
    );
  
  }
}