import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../data/models/course.dart';
import '../../widgets/course_card.dart';
import '../course/course_create_page.dart';
import '../course/course_detail_page.dart';
import '../attendance/course_attendance_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: const _AppBrandTitle(),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            tooltip: '搜索（待实现）',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 900 ? 24.0 : 16.0;
            return AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                final courses = store.courses;

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 88),
                  itemCount: courses.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _Header(theme: theme, count: courses.length);
                    }

                    final course = courses[index - 1];
                    final now = DateTime.now();
                    final canCheckIn = _canCheckIn(course, now);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CourseCard(
                          data: _toCardData(course),
                          onTap: () => _openDetail(context, course),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: canCheckIn
                                    ? () => _checkIn(context, course)
                                    : null,
                                child: const Text('打卡'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _openAttendance(context, course, true),
                                child: const Text('打卡记录'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(CourseCreatePage.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('新建课程'),
      ),
    );
  }

  CourseCardData _toCardData(Course course) {
    final now = DateTime.now();
    final remaining = course.remainingLessons;
    final total = course.totalLessons;

    final expiringByRemaining = remaining <= 2;
    final expiringByDate =
        course.endDate != null && course.endDate!.difference(now).inDays <= 7;

    final next = course.schedule.nextSession(now);
    final nextLabel = next == null ? '下一次：未设置' : '下一次：${_formatDateTime(next)}';
    final repeatLabel = course.schedule.repeatSummaryLabel();
    final makeupLabel = course.schedule.makeUpMethod.label;

    return CourseCardData(
      title: course.title,
      category: course.category,
      remaining: remaining,
      total: total,
      nextLessonLabel: '$nextLabel（$repeatLabel｜$makeupLabel）',
      isExpiring: expiringByRemaining || expiringByDate,
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.month}月${dt.day}日 $h:$m';
  }

  bool _canCheckIn(Course course, DateTime now) {
    final sessions = course.schedule.sessionsOnDay(now);
    if (sessions.isEmpty) return false;
    final duration = Duration(minutes: course.lessonDurationMinutes);
    for (final s in sessions) {
      final startWindow = s.subtract(const Duration(hours: 1));
      final endWindow = s.add(duration + const Duration(hours: 1));
      if (now.isAfter(startWindow) && now.isBefore(endWindow)) return true;
    }
    return false;
  }

  void _checkIn(BuildContext context, Course course) {
    final store = AppScope.of(context);
    final now = DateTime.now();
    final sessions = course.schedule.sessionsOnDay(now);
    if (sessions.isEmpty) return;
    store.checkIn(course.id, sessions.first);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打卡成功，课时 -1')),
    );
  }

  void _openAttendance(
    BuildContext context,
    Course course,
    bool makeUpMode,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseAttendancePage(course: course, makeUp: makeUpMode),
      ),
    );
  }

  void _openDetail(BuildContext context, Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(course: course),
      ),
    );
  }
}

class _AppBrandTitle extends StatelessWidget {
  const _AppBrandTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '课管家',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '智能课时记录与提醒助手',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.theme, required this.count});

  final ThemeData theme;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '你的课程（$count）',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(label: '全部', selected: true),
              _FilterChip(label: '即将到期'),
              _FilterChip(label: '本周有课'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
