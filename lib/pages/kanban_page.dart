import 'package:flutter/material.dart';
import '../models/task.dart';
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
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadTasks() async {
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

      if (!mounted) return;

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
        milestones = milestonesData;
      });
    } catch (e) {
      debugPrint('LOAD KANBAN ERROR: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
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
      debugPrint(e.toString());
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
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.projectName),
              Text(
                "${tasks.length} Tasks",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: "Pending (${pendingTasks.length})"),
              Tab(text: "In Progress (${inProgressTasks.length})"),
              Tab(text: "Completed (${completedTasks.length})"),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Manage labels',
              icon: const Icon(Icons.label_outline),
              onPressed: showManageLabelsDialog,
            ),

            IconButton(
              tooltip: 'Create task',
              icon: const Icon(Icons.add),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => TaskDialog(
                    title: "Create Task",
                    buttonText: "Create",
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
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () async {
                                  searchController.clear();
                                  await loadTasks();
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) async {
                        await loadTasks();
                      },
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        DropdownButton<String?>(
                          value: selectedPriority,
                          hint: const Text('Priority'),
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

                        const SizedBox(width: 12),

                        DropdownButton<String?>(
                          value: selectedAssigneeId,
                          hint: const Text('Assignee'),
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

                        const SizedBox(width: 12),

                        DropdownButton<String?>(
                          value: selectedLabelId,
                          hint: const Text('Label'),
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

                        const SizedBox(width: 12),

                        DropdownButton<String>(
                          value: selectedSortBy,
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

                        const SizedBox(width: 8),

                        IconButton(
                          tooltip: selectedSortOrder == 'ASC'
                              ? 'Ascending'
                              : 'Descending',
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
                      ],
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
      return const Center(child: Text("No Tasks"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
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
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                      style: TextStyle(color: Colors.grey.shade700),
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
                          style: const TextStyle(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: task.priority == "HIGH"
                          ? Colors.red.shade100
                          : task.priority == "MEDIUM"
                          ? Colors.orange.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      task.priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: task.priority == "HIGH"
                            ? Colors.red
                            : task.priority == "MEDIUM"
                            ? Colors.orange
                            : Colors.green,
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
                          ? Colors.red
                          : Colors.grey,
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
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: task.status == "PENDING"
                        ? Colors.orange.shade100
                        : task.status == "IN_PROGRESS"
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.status.replaceAll("_", " "),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: task.status == "PENDING"
                          ? Colors.orange
                          : task.status == "IN_PROGRESS"
                          ? Colors.blue
                          : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
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
