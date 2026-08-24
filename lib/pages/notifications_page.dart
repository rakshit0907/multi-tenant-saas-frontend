import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import 'task_details_page.dart';
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

  Future<void> openTaskNotification(
  NotificationModel notification,
) async {
  final taskId =
      notification.metadata?['taskId']?.toString();

  final projectId =
      notification.metadata?['projectId']?.toString();

  if (taskId == null || projectId == null) {
    debugPrint(
      'TASK NOTIFICATION ERROR: Missing taskId/projectId',
    );
    return;
  }

  try {
    final data = await ApiService.getTask(taskId);

    final task = Task.fromJson(data);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailsPage(
          task: task,
          projectId: projectId,
        ),
      ),
    );
  } catch (e) {
    debugPrint(
      'OPEN TASK NOTIFICATION ERROR: $e',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open this task',
        ),
      ),
    );
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

                        onTap: () async {
                          await markAsRead(notification);
                          if (!mounted) return;
                          
                          if (
                            notification.type ==
                                    NotificationType.taskAssigned ||
                                notification.type ==
                                    NotificationType.taskCompleted ||
                                notification.type ==
                                    NotificationType.taskStatusChanged
                          ) {
                           await openTaskNotification(notification);
                           return;
                          }

                          if (notification.type == 
                               NotificationType.projectInvitation) {
                            final invitationId = 
                                notification.metadata?['invitationId'];

                            if (invitationId == null) {
                              debugPrint("❌ No invitationId in notification metadata");
                              return;
                            }    

                            await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Project Invitation"),
                                content: Text(notification.message),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      try {
                                        await ApiService.rejectInvitation(
                                          invitationId.toString(),
                                        );

                                        if (!mounted) return;
                                        navigator.pop();
                                        await loadNotifications();
                                      } catch (e) {
                                        debugPrint("REJECT ERROR: $e");
                                      }  
                                    },
                                     child: const Text("Reject"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await ApiService.acceptInvitation(
                                          invitationId.toString(),
                                        );

                                        if (!mounted) return;
                                        navigator.pop();

                                        await loadNotifications();

                                        if (!mounted) return;

                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Invitation accepted. You are now a project member.",
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        debugPrint("ACCEPT ERROR: $e");
                                      }
                                    },
                                    child: const Text("ACCEPT"),
                                  ),
                                ],
                              ),
                            );
                           }
 
                        },
                      );
                    },
                  ),
                ),
    );
  }
}