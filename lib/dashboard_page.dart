import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'models/project.dart';
import 'services/api_service.dart';
import 'pages/members_page.dart';
import 'pages/project_dashboard_page.dart';
import 'pages/notifications_page.dart';
import 'models/workspace.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String userId = "";
  String tenantId = "";
  String role = "";
  String workspaceRole = "";

  List<Workspace> workspaces = [];
  Workspace? activeWorkspace;

  List<Project> projects = [];

  bool loading = true;
  bool switchingWorkspace = false;

  @override
  void initState() {
    super.initState();
    initializeDashboard();
  }

  Future<void> initializeDashboard() async {
    try {
      await loadUserInfo();
      await loadWorkspaces();
      await loadProjects();
    } catch (e) {
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await ApiService.deleteProject(projectId);
      setState(() {
        loading = true;
      });
      await loadProjects();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only the project owner can delete this project."),
        ),
      );
    }
  }

  Future<void> showCreateProjectDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    String selectedStatus = 'PLANNING';
    DateTime? startDate;
    DateTime? dueDate;
    bool submitting = false;
    String? errorMessage;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setDialogState(() {
                  startDate = picked;
                  errorMessage = null;
                });
              }
            }

            Future<void> pickDueDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dueDate ?? startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setDialogState(() {
                  dueDate = picked;
                  errorMessage = null;
                });
              }
            }

            Future<void> submit() async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Project name is required';
                });
                return;
              }

              if (startDate != null &&
                  dueDate != null &&
                  startDate!.isAfter(dueDate!)) {
                setDialogState(() {
                  errorMessage = 'Start date cannot be after the due date';
                });
                return;
              }

              setDialogState(() {
                submitting = true;
                errorMessage = null;
              });

              try {
                await ApiService.createProject(
                  name: name,
                  description: descriptionController.text,
                  status: selectedStatus,
                  startDate: startDate,
                  dueDate: dueDate,
                );

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  submitting = false;
                  errorMessage = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            String formatDate(DateTime? date) {
              if (date == null) return 'Not set';

              return '${date.day}/${date.month}/${date.year}';
            }

            return AlertDialog(
              title: const Text('Create Project'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Project name',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PLANNING',
                            child: Text('Planning'),
                          ),
                          DropdownMenuItem(
                            value: 'ACTIVE',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'ON_HOLD',
                            child: Text('On Hold'),
                          ),
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'ARCHIVED',
                            child: Text('Archived'),
                          ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.play_arrow),
                        title: const Text('Start date'),
                        subtitle: Text(formatDate(startDate)),
                        trailing: startDate == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    startDate = null;
                                  });
                                },
                              ),
                        onTap: submitting ? null : pickStartDate,
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Due date'),
                        subtitle: Text(formatDate(dueDate)),
                        trailing: dueDate == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setDialogState(() {
                                    dueDate = null;
                                  });
                                },
                              ),
                        onTap: submitting ? null : pickDueDate,
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (created != true || !mounted) return;

    setState(() {
      loading = true;
    });

    await loadProjects();
  }

  String formatProjectStatus(String status) {
    switch (status) {
      case 'PLANNING':
        return 'Planning';
      case 'ACTIVE':
        return 'Active';
      case 'ON_HOLD':
        return 'On Hold';
      case 'COMPLETED':
        return 'Completed';
      case 'ARCHIVED':
        return 'Archived';
      default:
        return status;
    }
  }

  String formatProjectDate(DateTime? date) {
    if (date == null) return 'Not set';

    final localDate = date.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year}';
  }

  Future<void> showEditProjectDialog(Project project) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(
      text: project.description ?? '',
    );

    String selectedStatus = project.status;
    DateTime? startDate = project.startDate;
    DateTime? dueDate = project.dueDate;

    final originalStartDate = project.startDate;
    final originalDueDate = project.dueDate;

    bool submitting = false;
    String? errorMessage;

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formatDate(DateTime? date) {
              if (date == null) return 'Not set';

              final localDate = date.toLocal();

              return '${localDate.day}/${localDate.month}/${localDate.year}';
            }

            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked == null) return;

              setDialogState(() {
                startDate = picked;
                errorMessage = null;
              });
            }

            Future<void> pickDueDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dueDate ?? startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked == null) return;

              setDialogState(() {
                dueDate = picked;
                errorMessage = null;
              });
            }

            Future<void> submit() async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Project name is required';
                });
                return;
              }

              if (startDate != null &&
                  dueDate != null &&
                  startDate!.isAfter(dueDate!)) {
                setDialogState(() {
                  errorMessage = 'Start date cannot be after the due date';
                });
                return;
              }

              setDialogState(() {
                submitting = true;
                errorMessage = null;
              });

              try {
                await ApiService.updateProject(
                  project.id,
                  name: name,
                  description: descriptionController.text,
                  status: selectedStatus,
                  startDate: startDate,
                  dueDate: dueDate,
                  clearStartDate:
                      originalStartDate != null && startDate == null,
                  clearDueDate: originalDueDate != null && dueDate == null,
                );

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                if (!dialogContext.mounted) return;

                setDialogState(() {
                  submitting = false;
                  errorMessage = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Project'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project name',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PLANNING',
                            child: Text('Planning'),
                          ),
                          DropdownMenuItem(
                            value: 'ACTIVE',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'ON_HOLD',
                            child: Text('On Hold'),
                          ),
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'ARCHIVED',
                            child: Text('Archived'),
                          ),
                        ],
                        onChanged: submitting
                            ? null
                            : (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              },
                      ),

                      const SizedBox(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.play_arrow),
                        title: const Text('Start date'),
                        subtitle: Text(formatDate(startDate)),
                        trailing: startDate == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: submitting
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          startDate = null;
                                        });
                                      },
                              ),
                        onTap: submitting ? null : pickStartDate,
                      ),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Due date'),
                        subtitle: Text(formatDate(dueDate)),
                        trailing: dueDate == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: submitting
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          dueDate = null;
                                        });
                                      },
                              ),
                        onTap: submitting ? null : pickDueDate,
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();

    if (updated != true || !mounted) return;

    setState(() {
      loading = true;
    });

    await loadProjects();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final decodedToken = JwtDecoder.decode(token);

    if (!mounted) return;

    setState(() {
      userId = decodedToken['userId']?.toString() ?? '';
      tenantId = decodedToken['tenantId']?.toString() ?? '';
      role = decodedToken['role']?.toString() ?? '';
      workspaceRole = decodedToken['workspaceRole']?.toString() ?? '';
    });
  }

  Future<void> loadProjects() async {
    try {
      final data = await ApiService.getProjects();

      setState(() {
        projects = data.map<Project>((e) => Project.fromJson(e)).toList();

        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> loadWorkspaces() async {
    final data = await ApiService.getWorkspaces();

    Workspace? selectedWorkspace;

    for (final workspace in data) {
      if (workspace.id == tenantId) {
        selectedWorkspace = workspace;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      workspaces = data;
      activeWorkspace = selectedWorkspace;
    });
  }

  Future<void> switchWorkspace(Workspace workspace) async {
    if (workspace.id == tenantId || switchingWorkspace) {
      return;
    }

    setState(() {
      switchingWorkspace = true;
    });

    try {
      await ApiService.switchWorkspace(workspace.id);

      // Decode the newly issued JWT.
      await loadUserInfo();

      // Reload workspace list and all workspace-scoped dashboard data.
      await loadWorkspaces();
      await loadProjects();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          switchingWorkspace = false;
        });
      }
    }
  }

  Future<void> showWorkspaceSelector() async {
    if (workspaces.isEmpty || switchingWorkspace) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Switch workspace',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...workspaces.map((workspace) {
                final isActive = workspace.id == tenantId;

                return ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.business_outlined,
                  ),
                  title: Text(workspace.name),
                  subtitle: Text(workspace.role),
                  trailing: isActive ? const Text('Active') : null,
                  enabled: !switchingWorkspace,
                  onTap: isActive
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          await switchWorkspace(workspace);
                        },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateProjectDialog,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: InkWell(
          onTap: showWorkspaceSelector,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_outlined, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    activeWorkspace?.name ?? 'Workspace',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                if (switchingWorkspace)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
          ),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),

                if (activeWorkspace != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${activeWorkspace!.name} • $workspaceRole'),
                    ),
                  ),

                const Divider(),

                Expanded(
                  child: ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];

                      return Card(
                        child: ListTile(
                          title: Text(project.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (project.description != null &&
                                  project.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  project.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 6),

                              Text(
                                '${formatProjectStatus(project.status)} | '
                                'Due: ${formatProjectDate(project.dueDate)}',
                              ),
                            ],
                          ),

                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => SafeArea(
                                child: Wrap(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.view_kanban),
                                      title: const Text("Open Kanban"),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProjectDashboardPage(
                                                  projectId: project.id,
                                                  projectName: project.name,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.group),
                                      title: const Text("View Members"),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MembersPage(
                                              projectId: project.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },

                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return AlertDialog(
                                    title: const Text("Delete Project"),
                                    content: Text("Delete '${project.name}'?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          Navigator.pop(dialogContext);

                                          await deleteProject(project.id);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
