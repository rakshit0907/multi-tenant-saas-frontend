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