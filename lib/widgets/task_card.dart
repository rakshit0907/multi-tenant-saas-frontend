import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  Color getPriorityColor(String? priority) {
    switch (priority) {
      case 'HIGH':
        return AppColors.primary;
      case 'MEDIUM':
        return AppColors.accent;
      case 'LOW':
        return AppColors.secondary;
      default:
        return AppColors.border;
    }
  }

  Color getLabelColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');

      if (cleaned.length != 6) {
        return AppColors.textSecondary;
      }

      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ListTile(
        leading: Icon(
          task.status == 'COMPLETED'
              ? Icons.check_circle
              : Icons.circle_outlined,
          color: task.status == 'COMPLETED'
              ? AppColors.success
              : AppColors.textSecondary,
        ),

        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: task.status == 'COMPLETED'
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Chip(
              label: Text(
                task.priority,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: getPriorityColor(task.priority),
            ),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  task.description!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),

            if (task.labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: task.labels.map((label) {
                    final color = getLabelColor(label.color);

                    return Chip(
                      label: Text(
                        label.name,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: color.withValues(alpha: 0.4)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
            PopupMenuItem(value: 'edit', child: Text("Edit")),
            PopupMenuItem(value: 'delete', child: Text("Delete")),
          ],
        ),
      ),
    );
  }
}
