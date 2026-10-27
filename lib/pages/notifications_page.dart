import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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
          .map<NotificationModel>((e) => NotificationModel.fromJson(e))
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

  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await ApiService.markNotificationAsRead(notification.id);

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

      case NotificationType.workspaceInvitation:
        return Icons.business_outlined;

      case NotificationType.taskAssigned:
        return Icons.assignment_ind_outlined;

      case NotificationType.taskCompleted:
        return Icons.task_alt;

      case NotificationType.taskStatusChanged:
        return Icons.sync_alt;

      case NotificationType.taskMentioned:
        return Icons.alternate_email;

      case NotificationType.memberAdded:
        return Icons.person_add_outlined;

      case NotificationType.memberRemoved:
        return Icons.person_remove_outlined;
    }
  }

  Future<void> openTaskNotification(NotificationModel notification) async {
    final taskId = notification.metadata?['taskId']?.toString();

    final projectId =
        notification.metadata?['projectId']?.toString() ??
        notification.projectId;

    if (taskId == null || projectId == null) {
      debugPrint('TASK NOTIFICATION ERROR: Missing taskId/projectId');
      return;
    }

    try {
      final data = await ApiService.getTask(taskId);

      final task = Task.fromJson(data);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailsPage(task: task, projectId: projectId),
        ),
      );
    } catch (e) {
      debugPrint('OPEN TASK NOTIFICATION ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open this task')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              unreadCount == 0
                  ? 'You’re all caught up'
                  : '$unreadCount unread ${unreadCount == 1 ? 'notification' : 'notifications'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accessiblePrimary,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Loading notifications...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: const Border.fromBorderSide(
                          BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 32,
                        color: AppColors.accessibleSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'You’re all caught up',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'New updates from your workspace will appear here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg,
                ),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: notification.isRead
                            ? AppColors.surface
                            : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: notification.isRead
                              ? AppColors.border
                              : AppColors.primary.withValues(alpha: 0.28),
                        ),
                      ),
                      child: ListTile(
                        tileColor: notification.isRead
                            ? null
                            : Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08),

                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? AppColors.background
                                : AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            getNotificationIcon(notification.type),
                            color: notification.isRead
                                ? AppColors.accessibleSecondary
                                : AppColors.accessiblePrimary,
                            size: 22,
                          ),
                        ),

                        title: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                        ),

                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxs),
                          child: Text(
                            notification.message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                          ),
                        ),

                        trailing: notification.isRead
                            ? null
                            : Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                  color: AppColors.accessiblePrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),

                        onTap: () async {
                          await markAsRead(notification);
                          if (!mounted) return;

                          if (notification.type ==
                                  NotificationType.taskAssigned ||
                              notification.type ==
                                  NotificationType.taskCompleted ||
                              notification.type ==
                                  NotificationType.taskStatusChanged ||
                              notification.type ==
                                  NotificationType.taskMentioned) {
                            await openTaskNotification(notification);
                            return;
                          }

                          if (notification.type ==
                              NotificationType.workspaceInvitation) {
                            final invitationId = notification
                                .metadata?['invitationId']
                                ?.toString();

                            if (invitationId == null || invitationId.isEmpty) {
                              debugPrint(
                                'WORKSPACE INVITATION ERROR: Missing invitationId',
                              );
                              return;
                            }

                            await showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Workspace Invitation'),
                                content: Text(notification.message),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),

                                  TextButton(
                                    onPressed: () async {
                                      final dialogNavigator = Navigator.of(
                                        dialogContext,
                                      );
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );

                                      try {
                                        await ApiService.rejectWorkspaceInviteById(
                                          invitationId,
                                        );

                                        if (!mounted) return;

                                        dialogNavigator.pop();

                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Workspace invitation rejected',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;

                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceFirst(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('REJECT'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      final dialogNavigator = Navigator.of(
                                        dialogContext,
                                      );
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );

                                      try {
                                        final result =
                                            await ApiService.acceptWorkspaceInviteById(
                                              invitationId,
                                            );

                                        final newToken = result['token']
                                            ?.toString();

                                        if (newToken == null ||
                                            newToken.isEmpty) {
                                          throw Exception(
                                            'Workspace token was not returned',
                                          );
                                        }

                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        await prefs.setString(
                                          'token',
                                          newToken,
                                        );

                                        if (!mounted) return;

                                        dialogNavigator.pop();

                                        navigator.pushNamedAndRemoveUntil(
                                          '/dashboard',
                                          (route) => false,
                                        );
                                      } catch (e) {
                                        debugPrint(
                                          'ACCEPT WORKSPACE INVITATION ERROR: $e',
                                        );

                                        if (!mounted) return;

                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceFirst(
                                                'Exception: ',
                                                '',
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('ACCEPT'),
                                  ),
                                ],
                              ),
                            );

                            return;
                          }

                          if (notification.type ==
                              NotificationType.projectInvitation) {
                            final invitationId =
                                notification.metadata?['invitationId'];

                            if (invitationId == null) {
                              debugPrint(
                                "❌ No invitationId in notification metadata",
                              );
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
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
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
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
