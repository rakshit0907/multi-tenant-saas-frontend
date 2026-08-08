import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/task_dialog.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;
  final List members;

  const TaskDetailsPage({
    super.key,
    required this.task,
    this.members = const [],
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  late DateTime? selectedDueDate;
  late String selectedPriority;
  late String selectedStatus;
  String? selectedAssigneeId;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.task.title,
    );

    descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );

    selectedDueDate = widget.task.dueDate;
    selectedPriority = widget.task.priority;
    selectedStatus = widget.task.status;
    selectedAssigneeId = null;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task title cannot be empty'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await ApiService.updateTask(
        widget.task.id,
        titleController.text.trim(),
        descriptionController.text.trim(),
        selectedDueDate,
        selectedPriority,
        selectedStatus,
        selectedAssigneeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        selectedDueDate = picked;
      });
    }
  }

  void openEditDialog() {
    showDialog(
      context: context,
      builder: (_) => TaskDialog(
        title: 'Edit Task',
        buttonText: 'Save',
        members: widget.members,
        initialTitle: titleController.text,
        initialDescription: descriptionController.text,
        initialDueDate: selectedDueDate,
        initialPriority: selectedPriority,
        initialStatus: selectedStatus,
        initialAssigneeId: selectedAssigneeId,
        onSave: (
          title,
          description,
          dueDate,
          priority,
          status,
          assigneeId,
        ) async {
          try {
            await ApiService.updateTask(
              widget.task.id,
              title,
              description,
              dueDate,
              priority,
              status,
              assigneeId,
            );

            if (!mounted) return;

            Navigator.pop(context, true);
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update task: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: openEditDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (task.description != null &&
                task.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
            ],

            buildInfoRow(
              Icons.flag,
              'Priority',
              task.priority,
            ),

            buildInfoRow(
              Icons.info_outline,
              'Status',
              task.status.replaceAll('_', ' '),
            ),

            if (task.dueDate != null)
              buildInfoRow(
                Icons.calendar_today,
                'Due Date',
                '${task.dueDate!.day.toString().padLeft(2, '0')}/'
                    '${task.dueDate!.month.toString().padLeft(2, '0')}/'
                    '${task.dueDate!.year}',
              ),

            buildInfoRow(
              task.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              'Completion',
              task.completed ? 'Completed' : 'Not Completed',
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saving ? null : saveTask,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  saving ? 'Saving...' : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
