class TaskStats {
  final int total;
  final int completed;
  final int pending;

  TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) {
    return TaskStats(
      total: json['total'] as int,
      completed: json['done'] as int,
      // "Pending" means not completed yet: to-do plus in-progress.
      pending: (json['todo'] as int) + (json['inProgress'] as int),
    );
  }
}
