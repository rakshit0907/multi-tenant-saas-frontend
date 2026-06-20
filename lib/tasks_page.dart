import 'package:flutter/material.dart';
import 'models/task.dart';
import 'services/api_service.dart';

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
  bool loading = true;
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
  final TextEditingController titleController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> createTask() async {
    try {
      await ApiService.createTask(
        widget.projectId,
        titleController.text,
      );

      titleController.clear();

      if (!mounted) return;

      Navigator.pop(context);

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
      final data =
          await ApiService.getTasks(widget.projectId);

      setState(() {
        tasks = data
            .map<Task>((e) => Task.fromJson(e))
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
          : tasks.isEmpty
              ? const Center(
                  child: Text(
                    "No tasks found",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];

                    return Card(
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text(task.id),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                task.completed
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                               ),
                               onPressed: () {
                                 toggleTask(task.id);
                               },
                             ),
                             IconButton(
                               icon: const Icon(Icons.delete),
                               onPressed: () {
                                 deleteTask(task.id);
                             },
                            ),
                           ],
                          ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text("Create Task"),
                content: TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: "Task title",
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: createTask,
                    child: const Text("Create"),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}