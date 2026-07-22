import 'package:flutter/material.dart';

class KanbanPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const KanbanPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<KanbanPage> createState() => _KanbanPageState();
}

class _KanbanPageState extends State<KanbanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
      ),
      body: Row(
        children: const [
          Expanded(
            child: KanbanColumn(
              title: "Pending",
              color: Colors.orange,
            ),
          ),
          Expanded(
            child: KanbanColumn(
              title: "In Progress",
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: KanbanColumn(
              title: "Completed",
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text("No Tasks"),
            ),
          ),
        ],
      ),
    );
  }
}