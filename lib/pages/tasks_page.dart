import 'package:flutter/material.dart';
import 'dart:async';
import '../models/task.dart';
import '../models/task_stats.dart';
import '../models/task_label.dart';
import '../services/api_service.dart';

import '../widgets/task_card.dart';
import '../widgets/task_dialog.dart';
import '../widgets/task_stats_card.dart';
class TasksPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const TasksPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<Task> tasks = [];
  TaskStats? stats;
  List members = [];
  List<TaskLabel> labels = [];
  
  final TextEditingController searchController =
    TextEditingController();
  
  String searchQuery = '';
  bool loading = true;
  
  String? myProjectRole;
  String selectedFilter = "All";
  String? selectedLabelId;
  String sortBy = 'dueDate';
  String sortOrder = 'ASC';

  Timer? _searchDebounce;


  final List<String> filters = [
  "All",
  "Pending",
  "Completed",
  "High",
  "Medium",
  "Low",
];
  @override
  void initState() {
    super.initState();
    loadPageData();
  }

  Future<void> loadPageData() async {
   try {
     await Future.wait([
       loadTasks(),
       loadMembers(),
       loadLabels(),
       loadMyProjectRole(),
     ]);

     if (!mounted) return;

     setState(() {
       loading = false;
     });
     } catch (e) {
       debugPrint("LOAD PAGE ERROR: $e");

       if (!mounted) return;

       setState(() {
         loading = false;
       });
     }
 }

  Future<void> loadMembers() async {
  try {
    final data = await ApiService.getProjectMembers(
      widget.projectId,
    );

    if (!mounted) return;
    setState(() {
      members = data;
    });

    debugPrint("MEMBERS STATE AFTER SET: ${members.length}");
  } catch (e) {
    debugPrint("LOAD MEMBERS ERROR: $e");
  }
}

 Future<void> loadLabels() async {
  try {
    final data = await ApiService.getLabels(
      widget.projectId,
    );

    if (!mounted) return;

    setState(() {
      labels = data;
    });
  } catch (e) {
    debugPrint(
      'LOAD LABELS ERROR: $e',
    );
  }
}

 Future<void> loadMyProjectRole() async {
  try {
    final role = await ApiService.getMyProjectRole(
      widget.projectId,
    );

    if (!mounted) return;

    setState(() {
      myProjectRole = role;
    });
  } catch (e) {
    debugPrint('LOAD PROJECT ROLE ERROR: $e');
  }
}

 Future<void> _showLabelsDialog() async {
  await loadLabels();

  if (!mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isOwner = myProjectRole == 'OWNER';

          return AlertDialog(
            title: const Text('Project Labels'),
            content: SizedBox(
              width: double.maxFinite,
              child: labels.isEmpty
                  ? const Text('No labels created yet.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: labels.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final label = labels[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 8,
                            backgroundColor:
                                _labelColor(label.color),
                          ),
                          title: Text(label.name),
                          subtitle: Text(label.color),
                          trailing: isOwner
                              ? Row(
                                  mainAxisSize:
                                      MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                      ),
                                      onPressed: () async {
                                        await _showLabelEditor(
                                          label: label,
                                        );

                                        await loadLabels();

                                        if (!mounted) return;

                                        setDialogState(() {});
                                      },
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                      ),
                                      onPressed: () async {
                                        final deleted =
                                            await _confirmDeleteLabel(
                                          label,
                                        );

                                        if (!deleted) return;

                                        await loadLabels();

                                        if (!mounted) return;

                                        setDialogState(() {});
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Close'),
              ),
              if (isOwner)
                FilledButton.icon(
                  onPressed: () async {
                    await _showLabelEditor();

                    await loadLabels();

                    if (!mounted) return;

                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Label'),
                ),
            ],
          );
        },
      );
    },
  );
}

 Color _labelColor(String hex) {
  try {
    final cleaned = hex.replaceFirst('#', '');

    if (cleaned.length != 6) {
      return Colors.grey;
    }

    return Color(
      int.parse('FF$cleaned', radix: 16),
    );
  } catch (_) {
    return Colors.grey;
  }
}

  Future<void> _showLabelEditor({
  TaskLabel? label,
}) async {
  final controller = TextEditingController(
    text: label?.name ?? '',
  );

  String selectedColor =
      label?.color ?? '#6B7280';

  const colors = [
    '#EF4444',
    '#F97316',
    '#EAB308',
    '#22C55E',
    '#06B6D4',
    '#3B82F6',
    '#8B5CF6',
    '#EC4899',
    '#6B7280',
  ];

  try {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                label == null
                    ? 'Create Label'
                    : 'Edit Label',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Label name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colors.map((color) {
                      final selected =
                          selectedColor == color;

                      return InkWell(
                        borderRadius:
                            BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _labelColor(color),
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: selected
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name =
                        controller.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(this.context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Label name is required',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      if (label == null) {
                        await ApiService.createLabel(
                          widget.projectId,
                          name,
                          color: selectedColor,
                        );
                      } else {
                        await ApiService.updateLabel(
                          widget.projectId,
                          label.id,
                          name: name,
                          color: selectedColor,
                        );
                      }

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext);
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            label == null
                                ? 'Failed to create label'
                                : 'Failed to update label',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    label == null ? 'Create' : 'Save',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

 Future<bool> _confirmDeleteLabel(
  TaskLabel label,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Label'),
            content: Text(
              'Delete "${label.name}"? '
              'It will be removed from tasks using it.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!confirmed) return false;

  try {
    await ApiService.deleteLabel(
      widget.projectId,
      label.id,
    );

    if (selectedLabelId == label.id) {
      selectedLabelId = null;
      await loadTasks();
    }

    return true;
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete label'),
        ),
      );
    }

    return false;
  }
}

  Future<void> toggleTask(String taskId) async {
    try {
      await ApiService.toggleTask(taskId);


      await loadTasks();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await ApiService.deleteTask(taskId);

     

      await loadTasks();
    } catch (e) {
       debugPrint(e.toString());
    }
  }
  
  
  Future<void> loadTasks() async {
  try {
    String? status;
    String? priority;

    switch (selectedFilter) {
      case 'Pending':
        status = 'PENDING';
        break;

      case 'Completed':
        status = 'COMPLETED';
        break;

      case 'High':
        priority = 'HIGH';
        break;

      case 'Medium':
        priority = 'MEDIUM';
        break;

      case 'Low':
        priority = 'LOW';
        break;
    }

    final results = await Future.wait([
      ApiService.getTaskStats(
        widget.projectId,
      ),
      ApiService.getTasks(
        widget.projectId,
        search: searchQuery,
        status: status,
        priority: priority,
        labelId: selectedLabelId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      ),
    ]);

    final statsData = results[0] as Map<String, dynamic>;
    final tasksData = results[1] as List<dynamic>;

    final loadedTasks = tasksData
        .map<Task>(
          (e) => Task.fromJson(e),
        )
        .toList();

    if (!mounted) return;

    setState(() {
      stats = TaskStats.fromJson(statsData);
      tasks = loadedTasks;
    });
  } catch (e) {
    debugPrint(
      'LOAD TASKS ERROR: $e',
    );
  }
}

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        actions: [
          IconButton(
            tooltip: 'Manage Labels',
            icon: const Icon(Icons.label_outline),
            onPressed: _showLabelsDialog,
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
  padding: const EdgeInsets.all(12),
  child: TextField(
    controller: searchController,
    decoration: const InputDecoration(
      hintText: "Search by title or description..",
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
    onChanged: (value) {
      searchQuery = value;

      _searchDebounce?.cancel();

     _searchDebounce = Timer(
       const Duration(milliseconds: 400),
       () {
         loadTasks();
        },
     );
   },
  ),
),

                Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: filters.map((filter) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(filter),
            selected: selectedFilter == filter,
            onSelected: (_) {
              setState(() {
                selectedFilter = filter;
              });

              loadTasks();
            },
          ),
        );
      }).toList(),
    ),
  ),
),

if (labels.isNotEmpty)
  Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 4,
    ),
    child: DropdownButtonFormField<String?>(
      initialValue: selectedLabelId,
      decoration: const InputDecoration(
        labelText: 'Label',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Labels'),
        ),
        ...labels.map(
          (label) => DropdownMenuItem<String?>(
            value: label.id,
            child: Text(label.name),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          selectedLabelId = value;
        });

        loadTasks();
      },
    ),
  ),


               Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  ),
  child: Row(
    children: [
      const Text(
        'Sort:',
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: DropdownButtonFormField<String>(
          initialValue: sortBy,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
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
            DropdownMenuItem(
              value: 'status',
              child: Text('Status'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              sortBy = value;
            });

            loadTasks();
          },
        ),
      ),

      const SizedBox(width: 8),

      IconButton(
        tooltip: sortOrder == 'ASC'
            ? 'Ascending'
            : 'Descending',
        onPressed: () {
          setState(() {
            sortOrder =
                sortOrder == 'ASC'
                    ? 'DESC'
                    : 'ASC';
          });

          loadTasks();
        },
        icon: Icon(
          sortOrder == 'ASC'
              ? Icons.arrow_upward
              : Icons.arrow_downward,
        ),
      ),
    ],
  ),
),
                if (stats != null)
                  TaskStatsCard(stats: stats!),
                  Expanded(
  child: tasks.isEmpty
      ? Center(
          child: Text(
            searchQuery.isNotEmpty || selectedFilter != "All" || selectedLabelId != null
                ? "No matching tasks"
                : "No tasks yet",
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        )
      : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];

            return TaskCard(
              task: task,
              onToggle: () => toggleTask(task.id),
              onDelete: () => deleteTask(task.id),
              onEdit: () {
                showDialog(
                  context: context,
                  builder: (_) => TaskDialog(
                    title: "Edit Task",
                    buttonText: "Save",
                    members: members,
                    labels: labels,
                    initialTitle: task.title,
                    initialDescription: task.description ?? '',
                    initialDueDate: task.dueDate,
                    initialPriority: task.priority,
                    initialStatus: task.status,
                    initialAssigneeId: task.assigneeId,
                    initialLabelIds:
                          task.labels.map((label) => label.id).toList(),
                    onSave: (
                      title,
                      description,
                      dueDate,
                      priority,
                      status,
                      assigneeId,
                      labelIds,
                    ) async {
                      await ApiService.updateTask(
                        task.id,
                        title,
                        description,
                        dueDate,
                        priority,
                        status,
                        assigneeId,
                        labelIds: labelIds,
                      );

                      await loadTasks();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      ],
    ), 
        
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          debugPrint("Project ID: ${widget.projectId}");
            debugPrint("MEMBERS BEFORE CREATE DIALOG: $members");
          showDialog(
            context: context,
            builder: (_) => TaskDialog(
              title: "Create Task",
              buttonText: "Create",
              members: members,
              labels: labels,
                onSave: (
          title,
          description,
          dueDate,
          priority,
          status,
          assigneeId,
          labelIds,
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
          );

          await loadTasks();
        },
      )
    );
  },
)
    );
  }
}