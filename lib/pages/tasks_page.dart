import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_stats.dart';

import '../services/api_service.dart';

import '../widgets/task_card.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_stats_card.dart';
class TasksPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const TasksPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> tasks = [];
  TaskStats? stats;

  bool loading = true;

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController descriptionController =
    TextEditingController();

  DateTime? selectedDueDate;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> toggleTask(String taskId) async {
    try {
      await ApiService.toggleTask(taskId);

      setState(() {
        loading = true;
      });

      await loadTasks();
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await ApiService.deleteTask(taskId);

      setState(() {
        loading = true;
      });

      await loadTasks();
    } catch (e) {
      print(e);
    }
  }
  Future<void> createTask() async {
    try {
      await ApiService.createTask(
        widget.projectId,
        titleController.text,
        descriptionController.text,
        selectedDueDate,
      );
      titleController.clear();
      descriptionController.clear();
      selectedDueDate = null;

      if (!mounted) return;

        Navigator.pop(context);

        await loadTasks();
      } catch (e) {
        print(e);
      }
    }
  
  Future<void> editTask(
  String taskId,
  String currentTitle,
) async {
  final editController =
      TextEditingController(
    text: currentTitle,
  );
  showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text("Edit Task"),
      content: TextField(
        controller: editController,
      ),
      actions: [
  TextButton(
    onPressed: () {
      Navigator.pop(context);
    },
    child: const Text("Cancel"),
  ),
  ElevatedButton(
  onPressed: () async {
    await ApiService.updateTask(
      taskId,
      editController.text,
      '',
      null,
    );

    Navigator.pop(context);

    await loadTasks();
  },
  child: const Text("Save"),
),
],

    );
},
);
}
  Future<void> loadTasks() async {
    try {
      final statsData =
          await ApiService.getTaskStats(
        widget.projectId,
      );

      final tasksData =
          await ApiService.getTasks(
        widget.projectId,
      );

      setState(() {
        stats = TaskStats.fromJson(
          statsData,
        );

        tasks = tasksData
            .map<Task>(
              (e) => Task.fromJson(e),
            )
            .toList();

        loading = false;
      });
    } catch (e) {
      print("TASK ERROR:");
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
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
          : Column(
              children: [
                if (stats != null)
                  TaskStatsCard(stats: stats!),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text(
                            "No tasks found",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        )
                      : ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, index) {
    final task = tasks[index];

    return TaskCard(
      task: task,
      onToggle: () => toggleTask(task.id),
      onDelete: () => deleteTask(task.id),
      onEdit: () {
        showDialog(
          context: context,
          builder: (_) => TaskDialog(
            title: "Edit Task",
            buttonText: "Save",
            initialTitle: task.title,
            initialDescription:
                task.description ?? '',
            initialDueDate: task.dueDate,
            onSave: (
              title,
              description,
              dueDate,
            ) async {
              await ApiService.updateTask(
                task.id,
                title,
                description,
                dueDate,
              );

              await loadTasks();
            }
          ),
        );
      },
    );
  },
)
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
  child: const Icon(Icons.add),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => TaskDialog(
        title: "Create Task",
        buttonText: "Create",
        onSave: (
          title,
          description,
          dueDate,
        ) async {
          await ApiService.createTask(
            widget.projectId,
            title,
            description,
            dueDate,
          );

          await loadTasks();
        },
      )
    );
  },
)
    );
  }
}