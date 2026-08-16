enum NotificationType {
  projectInvitation,
  taskAssigned,
  taskCompleted,
  taskStatusChanged,
  memberAdded,
  memberRemoved,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? projectId;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.projectId,
    this.metadata,
  });

  factory NotificationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return NotificationModel(
      id: json['id'],
      type: _parseType(json['type']),
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      projectId: json['project']?['id'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'PROJECT_INVITATION':
        return NotificationType.projectInvitation;
      case 'TASK_ASSIGNED':
        return NotificationType.taskAssigned;
      case 'TASK_COMPLETED':
        return NotificationType.taskCompleted;
      case 'TASK_STATUS_CHANGED':
        return NotificationType.taskStatusChanged;
      case 'MEMBER_ADDED':
        return NotificationType.memberAdded;
      case 'MEMBER_REMOVED':
        return NotificationType.memberRemoved;
      default:
        throw Exception('Unknown notification type: $type');
    }
  }
}