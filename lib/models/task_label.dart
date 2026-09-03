class TaskLabel {
  final String id;
  final String name;
  final String color;

  const TaskLabel({required this.id, required this.name, required this.color});

  factory TaskLabel.fromJson(Map<String, dynamic> json) {
    return TaskLabel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6B7280',
    );
  }
}
