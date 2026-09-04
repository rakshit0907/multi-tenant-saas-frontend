import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../widgets/task_dialog.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_label.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;
  final String projectId;

  const TaskDetailsPage({
    super.key,
    required this.task,
    required this.projectId,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  List<dynamic> comments = [];
  List<dynamic> members = [];
  List<TaskLabel> labels = [];
  List<dynamic> attachments = [];

  bool loadingAttachments = true;
  bool uploadingAttachment = false;

  String? myRole;

  final TextEditingController commentController = TextEditingController();

  bool loadingComments = true;
  bool addingComment = false;

  late Task currentTask;

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? selectedDueDate;
  late String selectedPriority;
  late String selectedStatus;

  String? selectedAssigneeId;
  late Set<String> selectedLabelIds;

  bool saving = false;

  String? _getAssigneeName(String? assigneeId) {
    if (assigneeId == null) return null;

    for (final member in members) {
      if (member['user']?['id'] == assigneeId) {
        return member['user']?['name'];
      }
    }

    return null;
  }

  Future<void> loadMembers() async {
    try {
      final result = await ApiService.getProjectMembers(widget.projectId);

      if (!mounted) return;

      setState(() {
        members = result;
      });
    } catch (e) {
      debugPrint('Failed to load members: $e');
    }
  }

  Future<void> loadLabels() async {
    try {
      final data = await ApiService.getLabels(widget.projectId);

      if (!mounted) return;

      setState(() {
        labels = data;

        selectedLabelIds = selectedLabelIds
            .where((id) => labels.any((label) => label.id == id))
            .toSet();
      });
    } catch (e) {
      debugPrint('LOAD LABELS ERROR: $e');
    }
  }

  Future<void> loadMyRole() async {
    try {
      final role = await ApiService.getMyProjectRole(widget.projectId);

      if (!mounted) return;

      setState(() {
        myRole = role;
      });
    } catch (e) {
      debugPrint('LOAD ROLE ERROR: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    currentTask = widget.task;

    loadMembers();
    loadComments();
    loadMyRole();
    loadAttachments();

    titleController = TextEditingController(text: currentTask.title);

    descriptionController = TextEditingController(
      text: currentTask.description ?? '',
    );

    selectedDueDate = currentTask.dueDate;
    selectedPriority = currentTask.priority;
    selectedStatus = currentTask.status;
    selectedAssigneeId = widget.task.assigneeId;
    selectedLabelIds = currentTask.labels.map((label) => label.id).toSet();

    loadLabels();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    commentController.dispose();
    super.dispose();
  }

  Future<void> addComment() async {
    final content = commentController.text.trim();

    if (content.isEmpty) return;

    setState(() {
      addingComment = true;
    });

    try {
      await ApiService.addTaskComment(currentTask.id, content);

      commentController.clear();

      await loadComments();
    } catch (e) {
      debugPrint('ADD COMMENT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add comment')));
    } finally {
      if (mounted) {
        setState(() {
          addingComment = false;
        });
      }
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await ApiService.deleteTaskComment(commentId);

      await loadComments();
    } catch (e) {
      debugPrint('DELETE COMMENT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete comment')));
    }
  }

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
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
        labelIds: selectedLabelIds.toList(),
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
          labels: labels
              .where((label) => selectedLabelIds.contains(label.id))
              .toList(),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> loadComments() async {
    try {
      final data = await ApiService.getTaskComments(currentTask.id);

      if (!mounted) return;

      setState(() {
        comments = data;
        loadingComments = false;
      });
    } catch (e) {
      debugPrint('LOAD COMMENTS ERROR: $e');

      if (!mounted) return;

      setState(() {
        loadingComments = false;
      });
    }
  }

  Future<void> loadAttachments() async {
    try {
      final data = await ApiService.getTaskAttachments(currentTask.id);

      if (!mounted) return;

      setState(() {
        attachments = data;
        loadingAttachments = false;
      });
    } catch (e) {
      debugPrint('LOAD ATTACHMENTS ERROR: $e');

      if (!mounted) return;

      setState(() {
        loadingAttachments = false;
      });
    }
  }

  Future<void> pickAndUploadAttachment() async {
    try {
      final file = await FilePicker.pickFile();

      // User cancelled the picker
      if (file == null) {
        return;
      }

      final filePath = file.path;

      if (filePath == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to access selected file')),
        );

        return;
      }

      setState(() {
        uploadingAttachment = true;
      });

      await ApiService.uploadTaskAttachment(currentTask.id, filePath);

      await loadAttachments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attachment uploaded successfully')),
      );
    } catch (e) {
      debugPrint('UPLOAD ATTACHMENT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload attachment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          uploadingAttachment = false;
        });
      }
    }
  }

  Future<void> deleteAttachment(String attachmentId) async {
    try {
      await ApiService.deleteTaskAttachment(attachmentId);

      await loadAttachments();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attachment deleted')));
    } catch (e) {
      debugPrint('DELETE ATTACHMENT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete attachment: $e')),
      );
    }
  }

  void openEditDialog() {
    showDialog(
      context: context,
      builder: (_) => TaskDialog(
        title: 'Edit Task',
        buttonText: 'Save',
        members: members,
        initialTitle: currentTask.title,
        initialDescription: currentTask.description ?? '',
        initialDueDate: currentTask.dueDate,
        initialPriority: currentTask.priority,
        initialStatus: currentTask.status,
        initialAssigneeId: selectedAssigneeId,
        initialLabelIds: currentTask.labels.map((label) => label.id).toList(),
        onSave:
            (
              title,
              description,
              dueDate,
              priority,
              status,
              assigneeId,
              labelIds,
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
                  labelIds: labelIds,
                );

                if (!mounted) return;

                setState(() {
                  selectedLabelIds = labelIds.toSet();

                  final selectedLabels = labels
                      .where((label) => selectedLabelIds.contains(label.id))
                      .toList();
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
                    labels: selectedLabels,
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
                  const SnackBar(content: Text('Task updated successfully')),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update task: $e')),
                );
              }
            },
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          if (myRole == 'OWNER')
            IconButton(icon: const Icon(Icons.edit), onPressed: openEditDialog),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentTask.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            if (currentTask.description != null &&
                currentTask.description!.isNotEmpty) ...[
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                currentTask.description!,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
            ],

            buildInfoRow(Icons.flag, 'Priority', currentTask.priority),

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
              currentTask.assigneeName ?? 'Unassigned',
            ),

            if (currentTask.labels.isNotEmpty) ...[
              const Text(
                'Labels',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentTask.labels.map((label) {
                  return Chip(
                    label: Text(label.name),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            buildInfoRow(
              currentTask.completed
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              'Completion',
              currentTask.completed ? 'Completed' : 'Not Completed',
            ),

            const SizedBox(height: 12),

            const Divider(),
            const SizedBox(height: 16),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attachments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                if (uploadingAttachment)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: 'Add attachment',
                    onPressed: pickAndUploadAttachment,
                    icon: const Icon(Icons.attach_file),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (loadingAttachments)
              const Center(child: CircularProgressIndicator())
            else if (attachments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No attachments yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...attachments.map((attachment) {
                final name =
                    attachment['originalName']?.toString() ?? 'Attachment';

                final mimeType = attachment['mimeType']?.toString() ?? '';

                final uploader =
                    attachment['uploadedBy']?['name']?.toString() ?? 'Unknown';

                final attachmentId = attachment['id'].toString();

                IconData icon;

                if (mimeType.startsWith('image/')) {
                  icon = Icons.image_outlined;
                } else if (mimeType == 'application/pdf') {
                  icon = Icons.picture_as_pdf_outlined;
                } else {
                  icon = Icons.insert_drive_file_outlined;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(icon),
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('Uploaded by $uploader'),
                    trailing: IconButton(
                      tooltip: 'Delete attachment',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        deleteAttachment(attachmentId);
                      },
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 16),

            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (loadingComments)
              const Center(child: CircularProgressIndicator())
            else if (comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...comments.map((comment) {
                final author =
                    comment['author']?['name']?.toString() ?? 'Unknown user';

                final content = comment['content']?.toString() ?? '';

                final createdAtRaw = comment['createdAt']?.toString();

                String createdAt = '';

                if (createdAtRaw != null) {
                  final date = DateTime.tryParse(createdAtRaw)?.toLocal();

                  if (date != null) {
                    createdAt =
                        '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}/'
                        '${date.year} '
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}';
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 16),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                author,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            if (createdAt.isNotEmpty)
                              Text(
                                createdAt,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(content),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton.filled(
                  onPressed: addingComment ? null : addComment,
                  icon: addingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
