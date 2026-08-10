import 'package:flutter/material.dart';
enum TaskPriority {
  LOW, MEDIUM, HIGH,
}

enum TaskStatus {
  PENDING,
  IN_PROGRESS,
  COMPLETED,
}
class TaskDialog extends StatefulWidget {
  final List members;
  final String? initialAssigneeId;
  final String title;
  final String initialTitle;
  final String initialDescription;
  final DateTime? initialDueDate;
  final String initialPriority;
  final String initialStatus;
  final String buttonText;

  final Function(
    String title,
    String description,
    DateTime? dueDate,
    String priority,
    String status,
    String? assigneeId,
  ) onSave;

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
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Unassigned'),
      ),
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
    debugPrint("Dialog members: ${widget.members}");
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
              initialValue: selectedPriority,
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
                setState(() {
                  selectedPriority = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<TaskStatus>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(
                labelText: "Status",
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
                decoration: const InputDecoration(
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
              selectedStatus.name,
              selectedAssigneeId,
            );

            Navigator.pop(context);
          },
          child: Text(widget.buttonText),
        ),
      ],
    );
  }
}