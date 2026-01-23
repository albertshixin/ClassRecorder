import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../account/account_page.dart';
import '../../../data/models/course.dart';
import '../../widgets/course_card.dart';
import '../attendance/course_attendance_page.dart';
import '../course/course_create_page.dart';
import '../course/course_detail_page.dart';

enum _CourseFilter { all, expiringSoon, thisWeek }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _CourseFilter _filter = _CourseFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchMode = false;
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: _searchMode
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => setState(() => _keyword = value.trim()),
                  decoration: const InputDecoration(
                    hintText: '输入课程关键字',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              )
            : const _AppBrandTitle(),
        centerTitle: false,
        actions: [
          if (_searchMode)
            IconButton(
              onPressed: () {
                setState(() {
                  _keyword = '';
                  _searchController.clear();
                  _searchMode = false;
                });
              },
              icon: const Icon(Icons.close),
              tooltip: '退出搜索',
            )
          else
            IconButton(
              onPressed: () {
                setState(() => _searchMode = true);
                Future.microtask(() => _searchFocusNode.requestFocus());
              },
              icon: const Icon(Icons.search),
              tooltip: '搜索课程',
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AccountPage.routeName);
            },
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: '账号与安全',
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
                final now = DateTime.now();
                final courses = [..._filteredCourses(store.courses, now)]
                  ..sort((a, b) {
                    final an = a.schedule.nextSession(now);
                    final bn = b.schedule.nextSession(now);
                    if (an == null && bn == null) return 0;
                    if (an == null) return 1;
                    if (bn == null) return -1;
                    return an.compareTo(bn);
                  });

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 88),
                  itemCount: courses.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _Header(
                        theme: theme,
                        count: courses.length,
                        filter: _filter,
                        onFilterChanged: (value) => setState(() => _filter = value),
                      );
                    }

                    final course = courses[index - 1];
                    final now = DateTime.now();
                    final canCheckIn = _canCheckIn(course, now);
                    final hasAttendedToday = _hasAttendedToday(course, now);
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
                                    ? () async => _checkIn(context, course, hasAttendedToday)
                                    : null,
                                child: Text(hasAttendedToday ? '已打卡' : '打卡'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _openAttendance(
                                  context,
                                  course,
                                  makeUpMode: false,
                                  leaveMode: true,
                                ),
                                child: const Text('请假'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _openAttendance(
                                  context,
                                  course,
                                  makeUpMode: true,
                                  leaveMode: false,
                                ),
                                child: const Text('补卡'),
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

  List<Course> _filteredCourses(List<Course> source, DateTime now) {
    final filteredByType = switch (_filter) {
      _CourseFilter.expiringSoon =>
          source.where(_isExpiringSoon).toList(),
      _CourseFilter.thisWeek =>
          source.where((c) => _hasUpcomingThisWeek(c, now)).toList(),
      _CourseFilter.all => source,
    };

    return filteredByType.where(_matchesKeyword).toList();
  }

  bool _isExpiringSoon(Course course) {
    if (course.totalLessons <= 0) return false;
    return (course.remainingLessons / course.totalLessons) < 0.2;
  }

  bool _hasUpcomingThisWeek(Course course, DateTime now) {
    final next = course.schedule.nextSession(now);
    if (next == null) return false;
    final endOfWeek = DateTime(
      now.year,
      now.month,
      now.day + (DateTime.sunday - now.weekday),
      23,
      59,
      59,
    );
    return !next.isAfter(endOfWeek);
  }

  bool _matchesKeyword(Course course) {
    if (_keyword.isEmpty) return true;
    return course.title.toLowerCase().contains(_keyword.toLowerCase());
  }

  CourseCardData _toCardData(Course course) {
    final now = DateTime.now();
    final remaining = course.remainingLessons;
    final total = course.totalLessons;

    final expiringByRemaining = total > 0 && (remaining / total) < 0.2;
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

  bool _hasAttendedToday(Course course, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return course.attendanceRecords.any((r) =>
        r.status == AttendanceStatus.attended &&
        r.sessionStart.year == today.year &&
        r.sessionStart.month == today.month &&
        r.sessionStart.day == today.day);
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

  Future<void> _checkIn(BuildContext context, Course course, bool hasAttendedToday) async {
    final store = AppScope.of(context);
    if (hasAttendedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今天上课已经打过卡，不需要重复打卡')),
      );
      return;
    }
    final now = DateTime.now();
    final sessions = course.schedule.sessionsOnDay(now);
    if (sessions.isEmpty) return;
    await store.checkIn(course.id, sessions.first);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打卡成功，课时 -1')),
    );
  }

  void _openAttendance(
    BuildContext context,
    Course course, {
    required bool makeUpMode,
    required bool leaveMode,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseAttendancePage(
          course: course,
          makeUp: makeUpMode,
          leaveMode: leaveMode,
        ),
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
  const _Header({
    required this.theme,
    required this.count,
    required this.filter,
    required this.onFilterChanged,
  });

  final ThemeData theme;
  final int count;
  final _CourseFilter filter;
  final ValueChanged<_CourseFilter> onFilterChanged;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: '全部',
                selected: filter == _CourseFilter.all,
                onTap: () => onFilterChanged(_CourseFilter.all),
              ),
              _FilterChip(
                label: '即将到期',
                selected: filter == _CourseFilter.expiringSoon,
                onTap: () => onFilterChanged(_CourseFilter.expiringSoon),
              ),
              _FilterChip(
                label: '本周有课',
                selected: filter == _CourseFilter.thisWeek,
                onTap: () => onFilterChanged(_CourseFilter.thisWeek),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
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
      ),
    );
  }
}

