import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_stats.dart';

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
  
  final TextEditingController searchController =
    TextEditingController();
  
  String searchQuery = '';
  bool loading = true;
  
  String selectedFilter = "All";

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
    loadTasks();
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
      final statsData =
          await ApiService.getTaskStats(
        widget.projectId,
      );

      final tasksData =
          await ApiService.getTasks(
        widget.projectId,
      );
      List<Task> loadedTasks = tasksData
         .map<Task>((e) => Task.fromJson(e))
         .toList();

        loadedTasks.sort((a, b) {
          const priorityOrder = {
            'HIGH': 0,
            'MEDIUM': 1,
            'LOW': 2,
          };

          final priorityCompare =
              (priorityOrder[a.priority] ?? 3)
                  .compareTo(priorityOrder[b.priority] ?? 3);
          if (priorityCompare !=0) {
            return priorityCompare;
          }

          if (a.dueDate == null && b.dueDate == null) {
            return 0;
          }        

          if (a.dueDate == null) {
            return 1;
          }

          if (b.dueDate == null) {
            return -1;
          }

          return a.dueDate!.compareTo(b.dueDate!);
        }); 

        setState(() {
          stats = TaskStats.fromJson(statsData);
          tasks = loadedTasks;
          loading = false;
        });
        
      
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = tasks.where((task) {
      final query = searchQuery.toLowerCase();

final matchesSearch =
    task.title.toLowerCase().contains(query) ||
    (task.description?.toLowerCase().contains(query) ?? false);

  bool matchesFilter = true;

  switch (selectedFilter) {
  case "Pending":
    matchesFilter = !task.completed;
    break;

  case "Completed":
    matchesFilter = task.completed;
    break;

  case "High":
    matchesFilter = task.priority == "HIGH";
    break;

  case "Medium":
    matchesFilter = task.priority == "MEDIUM";
    break;

  case "Low":
    matchesFilter = task.priority == "LOW";
    break;

  default:
    matchesFilter = true;
}
  return matchesSearch && matchesFilter;
}).toList();
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
      setState(() {
        searchQuery = value;
      });
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
            },
          ),
        );
      }).toList(),
    ),
  ),
),

                if (stats != null)
                  TaskStatsCard(stats: stats!),
                  Expanded(
  child: filteredTasks.isEmpty
      ? Center(
          child: Text(
            searchQuery.isNotEmpty || selectedFilter != "All"
                ? "No matching tasks"
                : "No tasks yet",
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        )
      : ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];

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
                    initialTitle: task.title,
                    initialDescription: task.description ?? '',
                    initialDueDate: task.dueDate,
                    initialPriority: task.priority,
                    onSave: (
                      title,
                      description,
                      dueDate,
                      priority,
                      status,
                    ) async {
                      await ApiService.updateTask(
                        task.id,
                        title,
                        description,
                        dueDate,
                        priority,
                        status,
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
    showDialog(
      context: context,
      builder: (_) => TaskDialog(
        title: "Create Task",
        buttonText: "Create",
        onSave: (
          title,
          description,
          dueDate,
          priority,
          status,
        ) async {
          await ApiService.createTask(
            widget.projectId,
            title,
            description,
            dueDate,
            priority,
            status,
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