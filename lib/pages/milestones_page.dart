import 'package:flutter/material.dart';

import '../services/api_service.dart';

class MilestonesPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const MilestonesPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<MilestonesPage> createState() => _MilestonesPageState();
}

class _MilestonesPageState extends State<MilestonesPage> {
  List<dynamic> milestones = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadMilestones();
  }

  Future<void> loadMilestones() async {
    try {
      final data = await ApiService.getMilestones(widget.projectId);

      if (!mounted) return;

      setState(() {
        milestones = data;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'No target date';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'No target date';

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showMilestoneDialog({Map<String, dynamic>? milestone}) async {
    final editing = milestone != null;

    final nameController = TextEditingController(
      text: milestone?['name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: milestone?['description']?.toString() ?? '',
    );

    DateTime? selectedDate;

    final existingDate = milestone?['targetDate'];
    if (existingDate != null) {
      selectedDate = DateTime.tryParse(existingDate.toString())?.toLocal();
    }

    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editing ? 'Edit Milestone' : 'Create Milestone'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'No target date'
                                : '${selectedDate!.day}/'
                                      '${selectedDate!.month}/'
                                      '${selectedDate!.year}',
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Select'),
                          onPressed: saving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedDate = picked;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Milestone name is required'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            if (editing) {
                              await ApiService.updateMilestone(
                                widget.projectId,
                                milestone['id'].toString(),
                                name: name,
                                description: descriptionController.text.trim(),
                                targetDate: selectedDate,
                              );
                            } else {
                              await ApiService.createMilestone(
                                widget.projectId,
                                name: name,
                                description: descriptionController.text.trim(),
                                targetDate: selectedDate,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await loadMilestones();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  editing
                                      ? 'Milestone updated'
                                      : 'Milestone created',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(editing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _toggleStatus(Map<String, dynamic> milestone) async {
    final currentStatus = milestone['status']?.toString();
    final newStatus = currentStatus == 'COMPLETED' ? 'ACTIVE' : 'COMPLETED';

    try {
      await ApiService.updateMilestone(
        widget.projectId,
        milestone['id'].toString(),
        status: newStatus,
      );

      await loadMilestones();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteMilestone(Map<String, dynamic> milestone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Milestone'),
          content: Text('Delete "${milestone['name']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteMilestone(
        widget.projectId,
        milestone['id'].toString(),
      );

      await loadMilestones();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Milestone deleted')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.projectName} Milestones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMilestoneDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Milestone'),
      ),
      body: RefreshIndicator(
        onRefresh: loadMilestones,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(error!, textAlign: TextAlign.center),
                ],
              )
            : milestones.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.flag_outlined, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No milestones yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a milestone to track important project goals.',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: milestones.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final milestone = Map<String, dynamic>.from(
                    milestones[index],
                  );

                  final completed = milestone['status'] == 'COMPLETED';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                completed ? Icons.flag : Icons.flag_outlined,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  milestone['name']?.toString() ??
                                      'Unnamed milestone',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showMilestoneDialog(milestone: milestone);
                                  } else if (value == 'status') {
                                    _toggleStatus(milestone);
                                  } else if (value == 'delete') {
                                    _deleteMilestone(milestone);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'status',
                                    child: Text(
                                      completed ? 'Reopen' : 'Mark completed',
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (milestone['description']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 10),
                            Text(milestone['description'].toString()),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(_formatDate(milestone['targetDate'])),
                              const Spacer(),
                              Chip(
                                label: Text(completed ? 'Completed' : 'Active'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
