import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _tasks = [];

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  DateTime get _monthStart {
    return DateTime(_focusedMonth.year, _focusedMonth.month, 1);
  }

  DateTime get _monthEnd {
    return DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await ApiService.getCalendarTasks(
        start: _monthStart,
        end: _monthEnd,
      );

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<dynamic> _tasksForDate(DateTime date) {
    return _tasks.where((task) {
      final rawDueDate = task['dueDate']?.toString();

      if (rawDueDate == null || rawDueDate.isEmpty) {
        return false;
      }

      final dueDate = DateTime.tryParse(rawDueDate)?.toLocal();

      if (dueDate == null) {
        return false;
      }

      return _isSameDay(dueDate, date);
    }).toList();
  }

  List<dynamic> get _selectedDateTasks {
    return _tasksForDate(_selectedDate);
  }

  Future<void> _changeMonth(int amount) async {
    final newMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + amount,
      1,
    );

    setState(() {
      _focusedMonth = newMonth;
      _selectedDate = newMonth;
    });

    await _loadMonth();
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status ?? 'Unknown';
    }
  }

 Color _markerColorForTask(dynamic task) {
  final status = task['status']?.toString();
  final priority = task['priority']?.toString();

  if (status == 'COMPLETED') {
    return AppColors.accessibleSecondary;
  }

  switch (priority) {
    case 'HIGH':
      return AppColors.accessiblePrimary;
    case 'MEDIUM':
      return AppColors.accent;
    case 'LOW':
      return AppColors.accessibleSecondary;
    default:
      return AppColors.border;
  }
}

  @override
  Widget build(BuildContext context) {
    final selectedTasks = _selectedDateTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadMonth,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: _loading ? null : () => _changeMonth(-1),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.accessiblePrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_monthName(_focusedMonth.month)} '
                        '${_focusedMonth.year}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'YOUR SCHEDULE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: _loading ? null : () => _changeMonth(1),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.accessiblePrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          TableCalendar<dynamic>(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedMonth,
            headerVisible: false,

            selectedDayPredicate: (day) {
              return _isSameDay(day, _selectedDate);
            },

            eventLoader: (day) {
              return _tasksForDate(day);
            },

            onDaySelected: (selectedDay, focusedDay) async {
              final monthChanged =
                  selectedDay.year != _focusedMonth.year ||
                  selectedDay.month != _focusedMonth.month;

              setState(() {
                _selectedDate = selectedDay;
                _focusedMonth = DateTime(focusedDay.year, focusedDay.month, 1);
              });

              if (monthChanged) {
                await _loadMonth();
              }
            },

            onPageChanged: (focusedDay) async {
              final newMonth = DateTime(focusedDay.year, focusedDay.month, 1);

              if (newMonth.year == _focusedMonth.year &&
                  newMonth.month == _focusedMonth.month) {
                return;
              }

              setState(() {
                _focusedMonth = newMonth;
                _selectedDate = newMonth;
              });

              await _loadMonth();
            },

            daysOfWeekHeight: 36,
            rowHeight: 46,
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: const TextStyle(
                color: AppColors.accessiblePrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
              defaultDecoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              weekendDecoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accessiblePrimary,
                  width: 1.5,
                ),
              ),
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
              weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
              outsideTextStyle: const TextStyle(color: AppColors.textSecondary),
              selectedTextStyle: const TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
              ),
              todayTextStyle: const TextStyle(
                color: AppColors.accessiblePrimary,
                fontWeight: FontWeight.w700,
              ),
            ),

            calendarBuilders: CalendarBuilders<dynamic>(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) {
                  return null;
                }

                final visibleEvents = events.take(3).toList();

                return Positioned(
                  bottom: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: visibleEvents.map((task) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _markerColorForTask(task),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
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
                          'Loading your schedule...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_off_outlined,
                              size: 30,
                              color: AppColors.accessibleSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Unable to load calendar',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton(
                            onPressed: _loadMonth,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accessiblePrimary,
                              side: const BorderSide(color: AppColors.border),
                              minimumSize: const Size(120, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : selectedTasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: const Border.fromBorderSide(
                                BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: const Icon(
                              Icons.event_available_outlined,
                              size: 30,
                              color: AppColors.accessibleSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Nothing scheduled',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'No tasks due on '
                            '${_selectedDate.day}/'
                            '${_selectedDate.month}/'
                            '${_selectedDate.year}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = selectedTasks[index];

                      final project = task['project'];
                      final projectName = project is Map<String, dynamic>
                          ? project['name']?.toString()
                          : null;

                      final assignee = task['assignee'];
                      final assigneeName = assignee is Map<String, dynamic>
                          ? assignee['name']?.toString()
                          : null;

                      return Card(
                        color: AppColors.surface,
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.task_alt_outlined,
                              color: AppColors.accessiblePrimary,
                            ),
                          ),

                          title: Text(
                            task['title']?.toString() ?? 'Task',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (projectName != null)
                                Text(
                                  'Project: $projectName',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),

                              Text(
                                'Status: ${_formatStatus(task['status']?.toString())}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),

                              Text(
                                'Priority: ${task['priority'] ?? 'MEDIUM'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              if (assigneeName != null)
                                Text(
                                  'Assigned to: $assigneeName',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                            ],
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
