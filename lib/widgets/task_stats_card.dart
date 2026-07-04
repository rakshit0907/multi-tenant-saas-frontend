import 'package:flutter/material.dart';
import '../models/task_stats.dart';

class TaskStatsCard extends StatelessWidget {
  final TaskStats stats;

  const TaskStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: "Total",
              value: stats.total,
              color: Colors.blue,
            ),
            _StatItem(
              label: "Completed",
              value: stats.completed,
              color: Colors.green,
            ),
            _StatItem(
              label: "Pending",
              value: stats.pending,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}