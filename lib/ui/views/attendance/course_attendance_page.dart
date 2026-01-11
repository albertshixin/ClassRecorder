import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../data/models/course.dart';

class CourseAttendancePage extends StatefulWidget {
  const CourseAttendancePage({
    super.key,
    required this.course,
    this.makeUp = false,
  });

  final Course course;
  final bool makeUp;

  @override
  State<CourseAttendancePage> createState() => _CourseAttendancePageState();
}

class _CourseAttendancePageState extends State<CourseAttendancePage> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.makeUp ? '补卡记录' : '打卡记录'),
      ),
      body: Column(
        children: [
          _MonthSwitcher(
            month: _displayMonth,
            onChanged: (m) => setState(() => _displayMonth = m),
          ),
          Expanded(
            child: _Calendar(
              course: widget.course,
              month: _displayMonth,
              makeUp: widget.makeUp,
            ),
          ),
          _Legend(theme: theme),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.course,
    required this.month,
    required this.makeUp,
  });

  final Course course;
  final DateTime month;
  final bool makeUp;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1-7
    final cells = <Widget>[];
    final now = DateTime.now();
    final store = AppScope.of(context);

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final status = _statusForDay(course, date, now);
      final isMissedPast =
          status == _DayStatus.missed && date.isBefore(_dateOnly(now));
      final clickable = makeUp ? isMissedPast : false;

      cells.add(
        GestureDetector(
          onTap: clickable
              ? () async {
                  final sessions = course.schedule.sessionsOnDay(date);
                  if (sessions.isEmpty) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('补卡确认'),
                      content: Text('确定为 ${date.month}月${date.day}日 补卡？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('需要'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                  if (!context.mounted) return;
                  store.checkIn(course.id, sessions.first, makeUp: false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('补卡成功，课时 -1')),
                  );
                }
              : null,
          child: _DayCell(
            day: day,
            status: makeUp && !clickable ? _DayStatus.dimmed : status,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: cells,
      ),
    );
  }

  _DayStatus _statusForDay(Course course, DateTime day, DateTime now) {
    final sessions = course.schedule.sessionsOnDay(day);
    if (sessions.isEmpty) return _DayStatus.none;

    final recorded = course.attendanceRecords.where((r) {
      return r.sessionStart.year == day.year &&
          r.sessionStart.month == day.month &&
          r.sessionStart.day == day.day;
    }).toList();

    if (recorded.any((r) => r.status == AttendanceStatus.attended)) {
      return _DayStatus.attended;
    }
    if (recorded.any((r) => r.status == AttendanceStatus.leave)) {
      return _DayStatus.leave;
    }

    final today = _dateOnly(now);
    final target = _dateOnly(day);
    if (target.isBefore(today)) {
      return _DayStatus.missed;
    }
    if (target.isAtSameMomentAs(today)) {
      return _DayStatus.today;
    }
    return _DayStatus.upcoming;
  }
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

enum _DayStatus { none, attended, missed, leave, upcoming, today, dimmed }

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.status});

  final int day;
  final _DayStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colorForStatus(theme, status);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style:
                  theme.textTheme.bodyLarge?.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _colorForStatus(ThemeData theme, _DayStatus status) {
    switch (status) {
      case _DayStatus.attended:
        return _StatusColors(theme.colorScheme.primary, theme.colorScheme.onPrimary);
      case _DayStatus.missed:
        return _StatusColors(theme.colorScheme.error, theme.colorScheme.onError);
      case _DayStatus.leave:
        return _StatusColors(theme.colorScheme.tertiary, theme.colorScheme.onTertiary);
      case _DayStatus.upcoming:
        return _StatusColors(
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
        );
      case _DayStatus.today:
        return _StatusColors(
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
        );
      case _DayStatus.dimmed:
        return _StatusColors(
          theme.colorScheme.surfaceContainer,
          theme.colorScheme.onSurfaceVariant,
        );
      case _DayStatus.none:
        return _StatusColors(
          theme.colorScheme.surface,
          theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _StatusColors {
  const _StatusColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = '${month.year}年${month.month}月';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => onChanged(DateTime(month.year, month.month - 1, 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(label),
        IconButton(
          onPressed: () => onChanged(DateTime(month.year, month.month + 1, 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, Color>>[
      MapEntry('已上课', theme.colorScheme.primary),
      MapEntry('未上课', theme.colorScheme.error),
      MapEntry('请假', theme.colorScheme.tertiary),
      MapEntry('待上课', theme.colorScheme.secondaryContainer),
      MapEntry('今天', theme.colorScheme.primaryContainer),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        children: items
            .map(
              (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: item.value,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.key),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
