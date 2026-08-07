import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskDetailsPage extends StatelessWidget {
  final Task task;

  const TaskDetailsPage({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              task.description?.isNotEmpty == true
                  ? task.description!
                  : "No description",
            ),

            const Divider(height: 32),

            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text("Priority"),
              subtitle: Text(task.priority),
            ),

            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Status"),
              subtitle: Text(task.status),
            ),

            if (task.dueDate != null)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Due Date"),
                subtitle: Text(
                  "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                ),
              ),
          ],
        ),
      ),
    );
  }
}