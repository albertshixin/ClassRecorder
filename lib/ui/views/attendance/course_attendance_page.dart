import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../data/models/course.dart';

class CourseAttendancePage extends StatefulWidget {
  const CourseAttendancePage({
    super.key,
    required this.course,
    this.makeUp = false,
    this.leaveMode = false,
  });

  final Course course;
  final bool makeUp;
  final bool leaveMode;

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
    final store = AppScope.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final course = store.courses
            .firstWhere((c) => c.id == widget.course.id, orElse: () => widget.course);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.leaveMode
                ? '请假'
                : widget.makeUp
                    ? '补卡'
                    : '\u6253\u5361\u8bb0\u5f55'),
          ),
          body: Column(
            children: [
              _MonthSwitcher(
                month: _displayMonth,
                onChanged: (m) => setState(() => _displayMonth = m),
              ),
              Expanded(
                child: _Calendar(
                  course: course,
                  month: _displayMonth,
                  makeUp: widget.makeUp,
                  leaveMode: widget.leaveMode,
                  onChanged: (m) => setState(() => _displayMonth = m),
                ),
              ),
              _Legend(theme: theme),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.course,
    required this.month,
    required this.makeUp,
    required this.leaveMode,
    required this.onChanged,
  });

  final Course course;
  final DateTime month;
  final bool makeUp;
  final bool leaveMode;
  final ValueChanged<DateTime> onChanged;

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
      final recorded = _recordsForDay(course, date);
      final hasLeave = recorded.any((r) => r.status == AttendanceStatus.leave);
      final hasAttended = recorded.any((r) => r.status == AttendanceStatus.attended);

      bool clickable = false;
      if (leaveMode) {
        clickable = status != _DayStatus.none;
      } else if (makeUp) {
        clickable = isMissedPast || hasAttended;
      }

      cells.add(
        GestureDetector(
          onTap: clickable
              ? () async {
                  final sessions = course.schedule.sessionsOnDay(date);
                  if (sessions.isEmpty) return;
                  if (leaveMode) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(hasLeave ? '取消请假' : '申请请假'),
                        content: Text(hasLeave
                            ? '确定取消 ${date.month}月${date.day}日 的请假吗？'
                            : '确定为 ${date.month}月${date.day}日 请假吗？'),
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
                    if (confirm != true || !context.mounted) return;
                    await store.setLeave(course.id, sessions.first, leave: !hasLeave);
                  } else {
                    if (hasAttended) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('取消补卡'),
                          content: Text('确定取消 ${date.month}月${date.day}日 的补卡吗？'),
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
                      if (confirm != true || !context.mounted) return;
                      // 使用已存在的出勤记录时间，若无则fallback当天第一节课
                      final attendedRecord = recorded
                          .firstWhere((r) => r.status == AttendanceStatus.attended, orElse: () => CourseAttendanceRecord(sessionStart: sessions.first, status: AttendanceStatus.attended));
                      await store.removeCheckIn(course.id, attendedRecord.sessionStart);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已取消补卡，课时 +1')),
                      );
                      return;
                    }
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('\u8865\u5361\u786e\u8ba4'),
                        content: Text('\u786e\u5b9a\u4e3a ${date.month}\u6708${date.day}\u65e5 \u8865\u5361?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('\u53d6\u6d88'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('\u9700\u8981'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    if (!context.mounted) return;
                    await store.checkIn(course.id, sessions.first, makeUp: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('\u8865\u5361\u6210\u529f\uff0c\u8bfe\u65f6 -1')),
                    );
                  }
                }
              : null,
          child: _DayCell(
            day: day,
            status: status,
          ),
        ),
      );
    }

    const weekdays = ['\u4e00', '\u4e8c', '\u4e09', '\u56db', '\u4e94', '\u516d', '\u65e5'];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => onChanged(DateTime.now()),
                icon: const Icon(Icons.today),
                label: const Text('回到今天'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdays
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        '\u5468$w',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              childAspectRatio: 1,
              children: cells,
            ),
          ),
        ],
      ),
    );
  }

  _DayStatus _statusForDay(Course course, DateTime day, DateTime now) {
    final target = _dateOnly(day);
    final courseStart =
        course.startDate != null ? _dateOnly(course.startDate!) : null;
    final courseEnd = course.endDate != null ? _dateOnly(course.endDate!) : null;
    if (courseStart != null && target.isBefore(courseStart)) return _DayStatus.none;
    if (courseEnd != null && target.isAfter(courseEnd)) return _DayStatus.none;

    final sessions = course.schedule.sessionsOnDay(day);
    if (sessions.isEmpty) return _DayStatus.none;

    final recorded = _recordsForDay(course, day);

    if (recorded.any((r) => r.status == AttendanceStatus.attended)) {
      return _DayStatus.attended;
    }
    if (recorded.any((r) => r.status == AttendanceStatus.leave)) {
      return _DayStatus.leave;
    }

    final today = _dateOnly(now);
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

List<CourseAttendanceRecord> _recordsForDay(Course course, DateTime day) {
  return course.attendanceRecords.where((r) {
    return r.sessionStart.year == day.year &&
        r.sessionStart.month == day.month &&
        r.sessionStart.day == day.day;
  }).toList();
}

enum _DayStatus { none, attended, missed, leave, upcoming, today, dimmed }

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.status});

  final int day;
  final _DayStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colorForStatus(theme, status);
    final isOutlined = status == _DayStatus.upcoming;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOutlined ? Colors.transparent : colors.background,
              shape: BoxShape.circle,
              border: isOutlined
                  ? Border.all(color: colors.background, width: 2)
                  : null,
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
          theme.colorScheme.primary,
          theme.colorScheme.primary,
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
    final label = '${month.year}\u5e74${month.month}\u6708';
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
    final items = <_LegendItem>[
      _LegendItem('\u5df2\u4e0a\u8bfe', theme.colorScheme.primary),
      _LegendItem('\u672a\u4e0a\u8bfe', theme.colorScheme.error),
      _LegendItem('\u8bf7\u5047', theme.colorScheme.tertiary),
      _LegendItem('\u5f85\u4e0a\u8bfe', theme.colorScheme.primary, outlined: true),
      _LegendItem('\u4eca\u5929', theme.colorScheme.primaryContainer),
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
                      color: item.outlined ? Colors.transparent : item.color,
                      shape: BoxShape.circle,
                      border: item.outlined
                          ? Border.all(color: item.color, width: 2)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(item.label),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LegendItem {
  const _LegendItem(this.label, this.color, {this.outlined = false});

  final String label;
  final Color color;
  final bool outlined;
}







