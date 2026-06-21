class TaskStats {
  final int total;
  final int completed;
  final int pending;

  TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
  });

  factory TaskStats.fromJson(
    Map<String, dynamic> json,
  ) {
    return TaskStats(
      total: json['total'],
      completed: json['completed'],
      pending: json['pending'],
    );
  }
}