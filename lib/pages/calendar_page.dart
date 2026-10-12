import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';

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
      return Colors.green;
    }

    switch (priority) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: _loading ? null : () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(_focusedMonth.month)} '
                    '${_focusedMonth.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: _loading ? null : () => _changeMonth(1),
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

            calendarStyle: const CalendarStyle(),

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
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadMonth,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : selectedTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks due on '
                      '${_selectedDate.day}/'
                      '${_selectedDate.month}/'
                      '${_selectedDate.year}',
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
                        child: ListTile(
                          leading: const Icon(Icons.task_alt_outlined),
                          title: Text(task['title']?.toString() ?? 'Task'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (projectName != null)
                                Text('Project: $projectName'),
                              Text(
                                'Status: ${_formatStatus(task['status']?.toString())}',
                              ),
                              Text(
                                'Priority: '
                                '${task['priority'] ?? 'MEDIUM'}',
                              ),
                              if (assigneeName != null)
                                Text('Assigned to: $assigneeName'),
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
