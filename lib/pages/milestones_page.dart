import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                                    context: dialogContext,
                                    initialDate: selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );

                                  if (picked == null ||
                                      !dialogContext.mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    selectedDate = picked;
                                  });
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
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
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

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop(true);
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
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

    if (saved != true || !mounted) {
      return;
    }

    await loadMilestones();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(editing ? 'Milestone updated' : 'Milestone created'),
      ),
    );
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
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMilestoneDialog(),
        backgroundColor: AppColors.accessiblePrimary,
        foregroundColor: AppColors.surface,
        elevation: 1,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Milestone'),
      ),
      body: RefreshIndicator(
        onRefresh: loadMilestones,
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accessiblePrimary,
                ),
              )
            : error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Couldn’t load milestones',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: loadMilestones,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              )
            : milestones.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        size: 36,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No milestones yet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Break this project into milestones to track important goals.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMilestoneDialog(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create milestone'),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: milestones.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final milestone = Map<String, dynamic>.from(
                    milestones[index],
                  );

                  final completed = milestone['status'] == 'COMPLETED';

                  final taskCount =
                      int.tryParse(milestone['taskCount']?.toString() ?? '') ??
                      0;

                  final completedTaskCount =
                      int.tryParse(
                        milestone['completedTaskCount']?.toString() ?? '',
                      ) ??
                      0;

                  final progress =
                      int.tryParse(milestone['progress']?.toString() ?? '') ??
                      0;

                  final progressValue = (progress.clamp(0, 100)) / 100.0;

                  return Card(
                    margin: EdgeInsets.zero,
                    color: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                completed
                                    ? Icons.flag_rounded
                                    : Icons.flag_outlined,
                                color: completed
                                    ? AppColors.secondary
                                    : AppColors.accessiblePrimary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  milestone['name']?.toString() ??
                                      'Unnamed milestone',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz_rounded),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
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
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              milestone['description'].toString(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$completedTaskCount of $taskCount tasks completed',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '$progress%',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completed
                                  ? AppColors.secondary
                                  : AppColors.accessiblePrimary,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  _formatDate(milestone['targetDate']),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Chip(
                                label: Text(completed ? 'Completed' : 'Active'),
                                avatar: Icon(
                                  completed
                                      ? Icons.check_circle_outline
                                      : Icons.timelapse_rounded,
                                  size: 16,
                                  color: completed
                                      ? AppColors.secondary
                                      : AppColors.accessiblePrimary,
                                ),
                                backgroundColor: completed
                                    ? AppColors.secondary.withValues(
                                        alpha: 0.12,
                                      )
                                    : AppColors.accessiblePrimary.withValues(
                                        alpha: 0.08,
                                      ),
                                side: BorderSide(
                                  color: completed
                                      ? AppColors.secondary.withValues(
                                          alpha: 0.35,
                                        )
                                      : AppColors.accessiblePrimary.withValues(
                                          alpha: 0.25,
                                        ),
                                ),
                                labelStyle: TextStyle(
                                  color: completed
                                      ? AppColors.secondary
                                      : AppColors.accessiblePrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
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
