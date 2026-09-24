class Workspace {
  final String id;
  final String name;
  final String role;
  final DateTime? joinedAt;

  const Workspace({
    required this.id,
    required this.name,
    required this.role,
    this.joinedAt,
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
    );
  }
}
