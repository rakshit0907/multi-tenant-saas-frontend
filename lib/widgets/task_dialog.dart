import 'package:flutter/material.dart';
enum TaskPriority {
  LOW, MEDIUM, HIGH,
}
class TaskDialog extends StatefulWidget {
  final String title;
  final String initialTitle;
  final String initialDescription;
  final DateTime? initialDueDate;
  final String buttonText;

  final Function(
    String title,
    String description,
    DateTime? dueDate,
    String priority,
  ) onSave;

  const TaskDialog({
    super.key,
    required this.title,
    required this.buttonText,
    required this.onSave,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialDueDate,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? dueDate;
  TaskPriority selectedPriority = TaskPriority.MEDIUM;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.initialTitle,
    );

    descriptionController = TextEditingController(
      text: widget.initialDescription,
    );

    dueDate = widget.initialDueDate;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<TaskPriority>(
              value: selectedPriority,
              decoration: const InputDecoration(
                labelText: "Priority",
                border: OutlineInputBorder(),
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPriority = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),
            ListTile(
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
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              titleController.text.trim(),
              descriptionController.text.trim(),
              dueDate,
              selectedPriority.name,
            );

            Navigator.pop(context);
          },
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}