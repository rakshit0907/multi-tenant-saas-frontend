class WorkspaceMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? joinedAt;

  const WorkspaceMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.joinedAt,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      joinedAt: json['joinedAt'] == null
          ? null
          : DateTime.parse(json['joinedAt'] as String),
    );
  }
}
