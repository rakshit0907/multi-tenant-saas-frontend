import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> notifications = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();

      final loadedNotifications = data
          .map<NotificationModel>(
            (e) => NotificationModel.fromJson(e),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        notifications = loadedNotifications;
        loading = false;
      });
    } catch (e) {
      debugPrint("NOTIFICATIONS ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> markAsRead(
    NotificationModel notification,
  ) async {
    if (notification.isRead) return;

    try {
      await ApiService.markNotificationAsRead(
        notification.id,
      );

      await loadNotifications();
    } catch (e) {
      debugPrint("MARK READ ERROR: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();

      await loadNotifications();
    } catch (e) {
      debugPrint("MARK ALL READ ERROR: $e");
    }
  }

  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.projectInvitation:
        return Icons.mail_outline;

      case NotificationType.taskAssigned:
        return Icons.assignment_ind_outlined;

      case NotificationType.taskCompleted:
        return Icons.task_alt;

      case NotificationType.taskStatusChanged:
        return Icons.sync_alt;

      case NotificationType.memberAdded:
        return Icons.person_add_outlined;

      case NotificationType.memberRemoved:
        return Icons.person_remove_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text("Mark all read"),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "No notifications",
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadNotifications,
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification =
                          notifications[index];

                      return ListTile(
                        tileColor: notification.isRead
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08),

                        leading: CircleAvatar(
                          child: Icon(
                            getNotificationIcon(
                              notification.type,
                            ),
                          ),
                        ),

                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),

                        subtitle: Text(
                          notification.message,
                        ),

                        trailing: notification.isRead
                            ? null
                            : const Icon(
                                Icons.circle,
                                size: 10,
                              ),

                        onTap: () {
                          markAsRead(notification);
                        },
                      );
                    },
                  ),
                ),
    );
  }
}