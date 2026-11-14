import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../services/api_service.dart';
import '../widgets/task_dialog.dart';
import 'task_details_page.dart';
import '../models/task_label.dart';

class KanbanPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const KanbanPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.initialStatus,
  });

  final String? initialStatus;

  @override
  State<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends State<KanbanPage> {
  List<Task> tasks = [];
  List members = [];
  List<TaskLabel> labels = [];
  List<dynamic> milestones = [];
  bool loading = true;
  bool loadFailed = false;
  int _taskRequestId = 0;
  String? myProjectRole;

  bool get _isProjectOwner => myProjectRole == 'OWNER';

  final TextEditingController searchController = TextEditingController();

  String? selectedPriority;
  String? selectedAssigneeId;
  String? selectedLabelId;

  String selectedSortBy = 'dueDate';
  String selectedSortOrder = 'ASC';

  @override
  void initState() {
    super.initState();
    loadTasks();
    loadMyProjectRole();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadTasks() async {
    final requestId = ++_taskRequestId;
    try {
      final results = await Future.wait([
        ApiService.getProjectMembers(widget.projectId),
        ApiService.getTasks(
          widget.projectId,
          search: searchController.text.trim(),
          priority: selectedPriority,
          assigneeId: selectedAssigneeId,
          labelId: selectedLabelId,
          sortBy: selectedSortBy,
          sortOrder: selectedSortOrder,
        ),
        ApiService.getLabels(widget.projectId),
        ApiService.getMilestones(widget.projectId),
      ]);

      if (!mounted || requestId != _taskRequestId) return;

      final membersData = results[0];
      final tasksData = results[1];
      final labelsData = results[2] as List<TaskLabel>;
      debugPrint(
        'KANBAN LABELS: ${labelsData.map((label) => '${label.id}:${label.name}').toList()}',
      );
      final milestonesData = results[3];
      setState(() {
        members = membersData;
        tasks = tasksData.map<Task>((e) => Task.fromJson(e)).toList();
        labels = labelsData;
        loading = false;
        loadFailed = false;
        milestones = milestonesData;
      });
    } catch (e) {
      debugPrint('LOAD KANBAN ERROR: $e');

      if (!mounted || requestId != _taskRequestId) return;

      setState(() {
        loading = false;
        loadFailed = true;
      });

      if (tasks.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh tasks.')),
        );
      }
    }
  }

  Future<void> showManageLabelsDialog() async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Labels'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Label name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final name = nameController.text.trim();

                          if (name.isEmpty) {
                            return;
                          }

                          try {
                            await ApiService.createLabel(
                              widget.projectId,
                              name,
                            );

                            nameController.clear();

                            final updatedLabels = await ApiService.getLabels(
                              widget.projectId,
                            );

                            if (!mounted) return;

                            setState(() {
                              labels = updatedLabels;
                            });

                            setDialogState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Label created')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create label: $e'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Label'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (labels.isEmpty)
                      const Text('No labels yet')
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: labels.length,
                          itemBuilder: (context, index) {
                            final label = labels[index];

                            return ListTile(
                              leading: const Icon(Icons.label_outline),
                              title: Text(label.name),
                            );
                          },
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
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  Future<void> loadMyProjectRole() async {
    try {
      final role = await ApiService.getMyProjectRole(widget.projectId);

      if (!mounted) return;

      setState(() {
        myProjectRole = role;
      });
    } catch (e) {
      debugPrint('LOAD PROJECT ROLE ERROR: $e');
    }
  }

  Future<void> moveTask(Task task, String newColumn) async {
    String status;

    switch (newColumn) {
      case "Pending":
        status = "PENDING";
        break;

      case "In Progress":
        status = "IN_PROGRESS";
        break;

      case "Completed":
        status = "COMPLETED";
        break;

      default:
        status = "PENDING";
    }

    try {
      await ApiService.updateTaskStatus(task.id, status);

      await loadTasks();
    } catch (e) {
      debugPrint('MOVE TASK ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not change the status. Check your connection, or ask the '
            'project owner if this task is not assigned to you.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((t) => t.status == "PENDING").toList();

    final inProgressTasks = tasks
        .where((t) => t.status == "IN_PROGRESS")
        .toList();

    final completedTasks = tasks.where((t) => t.status == "COMPLETED").toList();

    int initialTab = 0;

    switch (widget.initialStatus) {
      case "IN_PROGRESS":
        initialTab = 1;
        break;

      case "COMPLETED":
        initialTab = 2;
        break;

      default:
        initialTab = 0;
    }

    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.projectName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.accessiblePrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accessiblePrimary,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            dividerColor: AppColors.border,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: 'Pending (${pendingTasks.length})'),
              Tab(text: 'In Progress (${inProgressTasks.length})'),
              Tab(text: 'Completed (${completedTasks.length})'),
            ],
          ),
          actions: [
            if (_isProjectOwner)
              IconButton(
                tooltip: 'Manage labels',
                icon: const Icon(Icons.label_outline_rounded),
                color: AppColors.accessibleSecondary,
                onPressed: showManageLabelsDialog,
              ),
            if (_isProjectOwner)
              IconButton(
                tooltip: 'Create task',
                icon: const Icon(Icons.add_rounded),
                color: AppColors.accessiblePrimary,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => TaskDialog(
                      title: 'Create Task',
                      buttonText: 'Create',
                      members: members,
                      milestones: milestones,
                      onSave:
                          (
                            title,
                            description,
                            dueDate,
                            priority,
                            status,
                            assigneeId,
                            labelIds,
                            milestoneId,
                          ) async {
                            await ApiService.createTask(
                              widget.projectId,
                              title,
                              description,
                              dueDate,
                              priority,
                              status,
                              assigneeId,
                              labelIds: labelIds,
                              milestoneId: milestoneId,
                            );

                            await loadTasks();
                          },
                    ),
                  );
                },
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accessiblePrimary,
                ),
              )
            : (loadFailed && tasks.isEmpty)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 40,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Could not load tasks.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            loadFailed = false;
                          });
                          loadTasks();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.accessibleSecondary,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () async {
                                  searchController.clear();
                                  setState(() {});
                                  await loadTasks();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.accessiblePrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) async {
                        await loadTasks();
                      },
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<String?>(
                              value: selectedPriority,
                              hint: const Text('Priority'),
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All priorities'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'LOW',
                                  child: Text('Low'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'MEDIUM',
                                  child: Text('Medium'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'HIGH',
                                  child: Text('High'),
                                ),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  selectedPriority = value;
                                });

                                await loadTasks();
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<String?>(
                              value: selectedAssigneeId,
                              hint: const Text('Assignee'),
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All assignees'),
                                ),
                                ...members.map((member) {
                                  final user = member['user'];
                                  return DropdownMenuItem<String?>(
                                    value: user?['id']?.toString(),
                                    child: Text(
                                      user?['name']?.toString() ?? 'Unknown',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  selectedAssigneeId = value;
                                });
                                await loadTasks();
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<String?>(
                              value: selectedLabelId,
                              hint: const Text('Label'),
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All labels'),
                                ),
                                ...labels.map((label) {
                                  return DropdownMenuItem<String?>(
                                    value: label.id,
                                    child: Text(label.name),
                                  );
                                }),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  selectedLabelId = value;
                                });
                                await loadTasks();
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButton<String>(
                              value: selectedSortBy,
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              items: const [
                                DropdownMenuItem(
                                  value: 'dueDate',
                                  child: Text('Due date'),
                                ),
                                DropdownMenuItem(
                                  value: 'title',
                                  child: Text('Title'),
                                ),
                                DropdownMenuItem(
                                  value: 'priority',
                                  child: Text('Priority'),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                setState(() {
                                  selectedSortBy = value;
                                });
                                await loadTasks();
                              },
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: IconButton(
                              tooltip: selectedSortOrder == 'ASC'
                                  ? 'Ascending'
                                  : 'Descending',
                              color: AppColors.accessiblePrimary,
                              icon: Icon(
                                selectedSortOrder == 'ASC'
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                              ),
                              onPressed: () async {
                                setState(() {
                                  selectedSortOrder = selectedSortOrder == 'ASC'
                                      ? 'DESC'
                                      : 'ASC';
                                });
                                await loadTasks();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: TabBarView(
                      children: [
                        KanbanColumn(
                          projectId: widget.projectId,
                          tasks: pendingTasks,
                          onMove: moveTask,
                        ),
                        KanbanColumn(
                          projectId: widget.projectId,
                          tasks: inProgressTasks,
                          onMove: moveTask,
                        ),
                        KanbanColumn(
                          projectId: widget.projectId,
                          tasks: completedTasks,
                          onMove: moveTask,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final String projectId;
  final List<Task> tasks;
  final Function(Task, String) onMove;

  const KanbanColumn({
    super.key,
    required this.projectId,
    required this.tasks,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  size: 28,
                  color: AppColors.accessibleSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No tasks to show',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Try adjusting your search or filters.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        return Card(
          color: AppColors.surface,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TaskDetailsPage(task: task, projectId: projectId),
                ),
              );
            },
            title: Text(
              task.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null && task.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),

                if (task.labels.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: task.labels.map((label) {
                      return Chip(
                        label: Text(
                          label.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: task.priority == 'HIGH'
                          ? AppColors.error
                          : task.priority == 'MEDIUM'
                          ? AppColors.accent
                          : AppColors.accessibleSecondary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: task.priority == 'MEDIUM'
                            ? AppColors.textPrimary
                            : AppColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (task.dueDate != null)
                  Text(
                    "${task.dueDate!.day.toString().padLeft(2, '0')}/"
                    "${task.dueDate!.month.toString().padLeft(2, '0')}/"
                    "${task.dueDate!.year}",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          task.dueDate!.isBefore(DateTime.now()) &&
                              task.status != "COMPLETED"
                          ? AppColors.accessiblePrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          task.dueDate!.isBefore(DateTime.now()) &&
                              task.status != "COMPLETED"
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: task.status == 'PENDING'
                        ? AppColors.accent
                        : task.status == 'IN_PROGRESS'
                        ? AppColors.accessiblePrimary
                        : AppColors.accessibleSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    task.status.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: task.status == 'PENDING'
                          ? AppColors.textPrimary
                          : AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Change task status',
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                onMove(task, value);
              },
              itemBuilder: (_) => [
                if (task.status != "PENDING")
                  const PopupMenuItem(
                    value: "Pending",
                    child: Text("Move to Pending"),
                  ),

                if (task.status != "IN_PROGRESS")
                  const PopupMenuItem(
                    value: "In Progress",
                    child: Text("Move to In Progress"),
                  ),

                if (task.status != "COMPLETED")
                  const PopupMenuItem(
                    value: "Completed",
                    child: Text("Move to Completed"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
