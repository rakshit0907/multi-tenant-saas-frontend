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
      List<Task> loadedTasks = tasksData
         .map<Task>((e) => Task.fromJson(e))
         .toList();

        loadedTasks.sort((a, b) {
          const priorityOrder = {
            'HIGH': 0,
            'MEDIUM': 1,
            'LOW': 2,
          };

          final priorityCompare =
              (priorityOrder[a.priority] ?? 3)
                  .compareTo(priorityOrder[b.priority] ?? 3);
          if (priorityCompare !=0) {
            return priorityCompare;
          }

          if (a.dueDate == null && b.dueDate == null) {
            return 0;
          }        

          if (a.dueDate == null) {
            return 1;
          }

          if (b.dueDate == null) {
            return -1;
          }

          return a.dueDate!.compareTo(b.dueDate!);
        }); 

        setState(() {
          stats = TaskStats.fromJson(statsData);
          tasks = loadedTasks;
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
              priority,
            ) async {
              await ApiService.updateTask(
                task.id,
                title,
                description,
                dueDate,
                priority,
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
          priority,
        ) async {
          await ApiService.createTask(
            widget.projectId,
            title,
            description,
            dueDate,
            priority,
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