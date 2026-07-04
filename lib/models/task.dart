class Task {
  final String id;
  final String title;
  final bool completed;

  final String? description;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    this.description,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],

      description: json['description'],

      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
    );
  }
}