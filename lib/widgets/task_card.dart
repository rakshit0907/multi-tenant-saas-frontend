import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  
  Color getPriorityColor(String? priority) {
  switch (priority) {
    case 'HIGH':
      return Colors.red;
    case 'MEDIUM':
      return Colors.orange;
    case 'LOW':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            task.completed
                ? Icons.check_circle
                : Icons.circle_outlined,
            color: task.completed
                ? Colors.green
                : Colors.grey,
          ),
          onPressed: onToggle,
        ),
        title: Row(
  children: [
    Expanded(
      child: Text(
        task.title,
        style: TextStyle(
          decoration: task.completed
              ? TextDecoration.lineThrough
              : null,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),

    const SizedBox(width: 8),

    Chip(
      label: Text(
        task.priority ?? "MEDIUM",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      backgroundColor: getPriorityColor(task.priority),
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap,
    ),
  ],
),

subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (task.description != null &&
        task.description!.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(task.description!),
      ),

            if (task.dueDate != null)
              Padding(
                padding:
                    const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;

              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text("Edit"),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }
}