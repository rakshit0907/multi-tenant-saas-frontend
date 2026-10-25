import 'package:flutter/material.dart';

import '../models/task_label.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum TaskPriority { LOW, MEDIUM, HIGH }

enum TaskStatus { PENDING, IN_PROGRESS, COMPLETED }

class TaskDialog extends StatefulWidget {
  final List members;
  final String? initialAssigneeId;
  final List<TaskLabel> labels;
  final List<String> initialLabelIds;
  final List milestones;
  final String? initialMilestoneId;
  final String title;
  final String initialTitle;
  final String initialDescription;
  final DateTime? initialDueDate;
  final String initialPriority;
  final String initialStatus;
  final String buttonText;

  final Future<void> Function(
    String title,
    String description,
    DateTime? dueDate,
    String priority,
    String status,
    String? assigneeId,
    List<String> labelIds,
    String? milestoneId,
  )
  onSave;

  const TaskDialog({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onSave,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialDueDate,
    this.initialPriority = "MEDIUM",
    this.initialStatus = "PENDING",
    this.members = const [],
    this.initialAssigneeId,
    this.labels = const [],
    this.initialLabelIds = const [],
    this.milestones = const [],
    this.initialMilestoneId,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? dueDate;
  late TaskPriority selectedPriority;
  late TaskStatus selectedStatus;
  String? selectedAssigneeId;
  late Set<String> selectedLabelIds;
  String? selectedMilestoneId;
  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.initialTitle);

    descriptionController = TextEditingController(
      text: widget.initialDescription,
    );

    dueDate = widget.initialDueDate;
    selectedPriority = TaskPriority.values.firstWhere(
      (priority) => priority.name == widget.initialPriority,
      orElse: () => TaskPriority.MEDIUM,
    );

    selectedStatus = TaskStatus.values.firstWhere(
      (priority) => priority.name == widget.initialStatus,
      orElse: () => TaskStatus.PENDING,
    );

    final memberIds = widget.members
        .map((member) => member['user']?['id']?.toString())
        .whereType<String>()
        .toSet();

    selectedAssigneeId = memberIds.contains(widget.initialAssigneeId)
        ? widget.initialAssigneeId
        : null;
    selectedLabelIds = widget.initialLabelIds.toSet();
    final milestoneIds = widget.milestones
        .map((milestone) => milestone['id']?.toString())
        .whereType<String>()
        .toSet();

    selectedMilestoneId = milestoneIds.contains(widget.initialMilestoneId)
        ? widget.initialMilestoneId
        : null;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> buildAssigneeItems() {
    final seenIds = <String>{};

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
    ];

    for (final member in widget.members) {
      final user = member['user'];

      if (user == null) {
        continue;
      }

      final id = user['id']?.toString();
      final name = user['name']?.toString();

      // Ignore members without a valid user ID
      if (id == null || id.isEmpty) {
        continue;
      }

      // Ignore duplicate users
      if (!seenIds.add(id)) {
        continue;
      }

      items.add(
        DropdownMenuItem<String>(
          value: id,
          child: Text(name ?? 'Unknown User'),
        ),
      );
    }

    return items;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final initialDate = dueDate ?? now;

    final firstDate = dueDate != null && dueDate!.isBefore(now)
        ? dueDate!
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        widget.title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.accessiblePrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.accessiblePrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedMilestoneId,
              decoration: InputDecoration(
                labelText: 'Milestone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.accessiblePrimary,
                    width: 1.5,
                  ),
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No Milestone'),
                ),
                ...widget.milestones.map<DropdownMenuItem<String>>((milestone) {
                  return DropdownMenuItem<String>(
                    value: milestone['id']?.toString(),
                    child: Text(
                      milestone['name']?.toString() ?? 'Unnamed Milestone',
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMilestoneId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<TaskPriority>(
              initialValue: selectedPriority,
              decoration: InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(
                    color: AppColors.accessiblePrimary,
                    width: 1.5,
                  ),
                ),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPriority = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<TaskStatus>(
              initialValue: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: TaskStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedAssigneeId,
              decoration: InputDecoration(
                labelText: 'Assign To',
                border: OutlineInputBorder(),
              ),
              items: buildAssigneeItems(),
              onChanged: (value) {
                setState(() {
                  selectedAssigneeId = value;
                });
              },
            ),

            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  dueDate == null
                      ? "Select Due Date"
                      : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: pickDate,
                ),
                onTap: pickDate,
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size(48, 48),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accessiblePrimary,
            foregroundColor: AppColors.surface,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onPressed: () {
            widget.onSave(
              titleController.text.trim(),
              descriptionController.text.trim(),
              dueDate,
              selectedPriority.name,
              selectedStatus.name,
              selectedAssigneeId,
              selectedLabelIds.toList(),
              selectedMilestoneId,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}
