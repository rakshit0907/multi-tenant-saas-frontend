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
  late Task currentTask;

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? selectedDueDate;
  late String selectedPriority;
  late String selectedStatus;

  String? selectedAssigneeId;

  bool saving = false;

  String? _getAssigneeName(String? assigneeId) {
    if (assigneeId == null) return null;

    for (final member in widget.members) {
      if (member['user']?['id'] == assigneeId) {
        return member['user']?['name'];
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    currentTask = widget.task;

    titleController = TextEditingController(
      text: currentTask.title,
    );

    descriptionController = TextEditingController(
      text: currentTask.description ?? '',
    );

    selectedDueDate = currentTask.dueDate;
    selectedPriority = currentTask.priority;
    selectedStatus = currentTask.status;
    selectedAssigneeId = widget.task.assigneeId;
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
        currentTask.id,
        titleController.text.trim(),
        descriptionController.text.trim(),
        selectedDueDate,
        selectedPriority,
        selectedStatus,
        selectedAssigneeId,
      );

      if (!mounted) return;

      setState(() {
        currentTask = Task(
          id: currentTask.id,
          title: titleController.text.trim(),
          completed: currentTask.completed,
          description: descriptionController.text.trim(),
          dueDate: selectedDueDate,
          priority: selectedPriority,
          status: selectedStatus,
          assigneeId: selectedAssigneeId,
          assigneeName: _getAssigneeName(selectedAssigneeId),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully'),
        ),
      );
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

  void openEditDialog() {
    showDialog(
      context: context,
      builder: (_) => TaskDialog(
        title: 'Edit Task',
        buttonText: 'Save',
        members: widget.members,
        initialTitle: currentTask.title,
        initialDescription: currentTask.description ?? '',
        initialDueDate: currentTask.dueDate,
        initialPriority: currentTask.priority,
        initialStatus: currentTask.status,
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
              currentTask.id,
              title,
              description,
              dueDate,
              priority,
              status,
              assigneeId,
            );

            if (!mounted) return;

            setState(() {
              currentTask = Task(
                id: currentTask.id,
                title: title,
                completed: currentTask.completed,
                description: description,
                dueDate: dueDate,
                priority: priority,
                status: status,
                assigneeId: assigneeId,
                assigneeName: _getAssigneeName(assigneeId),
              );

              titleController.text = title;
              descriptionController.text = description;
              selectedDueDate = dueDate;
              selectedPriority = priority;
              selectedStatus = status;
              selectedAssigneeId = assigneeId;
            });

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task updated successfully'),
              ),
            );
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
              currentTask.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (currentTask.description != null &&
                currentTask.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentTask.description!,
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
              currentTask.priority,
            ),

            buildInfoRow(
              Icons.info_outline,
              'Status',
              currentTask.status.replaceAll('_', ' '),
            ),

            if (currentTask.dueDate != null)
              buildInfoRow(
                Icons.calendar_today,
                'Due Date',
                '${currentTask.dueDate!.day.toString().padLeft(2, '0')}/'
                    '${currentTask.dueDate!.month.toString().padLeft(2, '0')}/'
                    '${currentTask.dueDate!.year}',
              ),

            buildInfoRow(
              Icons.person_outline,
              'Assigned To',
              currentTask.assigneeName ?? 'Uassigned',
            ),  

            

            buildInfoRow(
              currentTask.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              'Completion',
              currentTask.completed
                  ? 'Completed'
                  : 'Not Completed',
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

