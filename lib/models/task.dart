import 'task_label.dart';

class Task {
  final String id;
  final String title;
  final bool completed;
  final List<TaskLabel> labels;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final String? assigneeId;
  final String? assigneeName;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    this.description,
    this.dueDate,
    required this.priority,
    required this.status,
    this.assigneeId,
    this.assigneeName,
    this.labels = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'PENDING',
      assigneeId: json['assignee']?['id'],
      assigneeName: json['assignee']?['name'],
      labels:
          (json['labels'] as List<dynamic>?)
              ?.map(
                (label) => TaskLabel.fromJson(label as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}
