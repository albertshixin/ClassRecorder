
const Map<int, String> kCourseWeekdayLabels = {
  DateTime.monday: '周一',
  DateTime.tuesday: '周二',
  DateTime.wednesday: '周三',
  DateTime.thursday: '周四',
  DateTime.friday: '周五',
  DateTime.saturday: '周六',
  DateTime.sunday: '周日',
};

const List<int> kCourseWeekdayOrder = [
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

String courseWeekdayLabel(int weekday) =>
    kCourseWeekdayLabels[weekday] ?? '周$weekday';

enum CourseRepeatPattern { none, weekly, monthly }

extension CourseRepeatPatternLabel on CourseRepeatPattern {
  String get label {
    switch (this) {
      case CourseRepeatPattern.none:
        return '不重复';
      case CourseRepeatPattern.weekly:
        return '按周重复';
      case CourseRepeatPattern.monthly:
        return '按月重复';
    }
  }
}

enum CourseMakeUpMethod { autoPostpone, noMakeUp, reschedule }

extension CourseMakeUpMethodLabel on CourseMakeUpMethod {
  String get label {
    switch (this) {
      case CourseMakeUpMethod.autoPostpone:
        return '自动推迟到下次上课';
      case CourseMakeUpMethod.noMakeUp:
        return '不能补课';
      case CourseMakeUpMethod.reschedule:
        return '需要重新预约';
    }
  }
}

class ClassTimeOfDay {
  const ClassTimeOfDay({required this.hour, required this.minute})
      : assert(hour >= 0 && hour <= 23),
        assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  String format24h() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {
        'hour': hour,
        'minute': minute,
      };

  factory ClassTimeOfDay.fromJson(Map<String, dynamic> json) {
    return ClassTimeOfDay(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
    );
  }
}

class WeeklyCourseTime {
  const WeeklyCourseTime({required this.weekday, required this.time})
      : assert(weekday >= DateTime.monday && weekday <= DateTime.sunday);

  final int weekday;
  final ClassTimeOfDay time;

  DateTime nextAfter(DateTime reference) {
    final refDate = DateTime(reference.year, reference.month, reference.day);
    final dayOffset = (weekday - reference.weekday + 7) % 7;
    final candidateDate = refDate.add(Duration(days: dayOffset));
    var candidate = DateTime(
      candidateDate.year,
      candidateDate.month,
      candidateDate.day,
      time.hour,
      time.minute,
    );
    if (candidate.isBefore(reference)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  String formatLabel() => '${courseWeekdayLabel(weekday)} ${time.format24h()}';

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'time': time.toJson(),
      };

  factory WeeklyCourseTime.fromJson(Map<String, dynamic> json) {
    return WeeklyCourseTime(
      weekday: (json['weekday'] as num?)?.toInt() ?? DateTime.monday,
      time: ClassTimeOfDay.fromJson(
        (json['time'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }
}

class MonthlyCourseTime {
  const MonthlyCourseTime({required this.day, required this.time})
      : assert(day >= 1 && day <= 31);

  final int day;
  final ClassTimeOfDay time;

  DateTime? nextAfter(DateTime reference) {
    for (var monthOffset = 0; monthOffset < 24; monthOffset++) {
      final monthStart =
          DateTime(reference.year, reference.month + monthOffset, 1);
      final daysInMonth =
          DateTime(monthStart.year, monthStart.month + 1, 0).day;
      if (day > daysInMonth) continue;

      final candidate = DateTime(
        monthStart.year,
        monthStart.month,
        day,
        time.hour,
        time.minute,
      );
      if (!candidate.isBefore(reference)) return candidate;
    }
    return null;
  }

  String formatLabel() => '$day号 ${time.format24h()}';

  Map<String, dynamic> toJson() => {
        'day': day,
        'time': time.toJson(),
      };

  factory MonthlyCourseTime.fromJson(Map<String, dynamic> json) {
    return MonthlyCourseTime(
      day: (json['day'] as num?)?.toInt() ?? 1,
      time: ClassTimeOfDay.fromJson(
        (json['time'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }
}

class CourseSchedule {
  const CourseSchedule({
    this.initialSession,
    this.repeatPattern = CourseRepeatPattern.none,
    this.weeklySlots = const [],
    this.monthlySlots = const [],
    this.makeUpMethod = CourseMakeUpMethod.autoPostpone,
  });

  final DateTime? initialSession;
  final CourseRepeatPattern repeatPattern;
  final List<WeeklyCourseTime> weeklySlots;
  final List<MonthlyCourseTime> monthlySlots;
  final CourseMakeUpMethod makeUpMethod;

  /// 返回指定日期（仅当天）所有安排的上课时间点（含时分）。
  List<DateTime> sessionsOnDay(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);

    if (repeatPattern == CourseRepeatPattern.weekly) {
      if (weeklySlots.isEmpty) return const [];
      return weeklySlots
          .where((slot) => slot.weekday == dateOnly.weekday)
          .map((slot) => DateTime(
                dateOnly.year,
                dateOnly.month,
                dateOnly.day,
                slot.time.hour,
                slot.time.minute,
              ))
          .toList();
    }

    if (repeatPattern == CourseRepeatPattern.monthly) {
      if (monthlySlots.isEmpty) return const [];
      return monthlySlots
          .where((slot) => slot.day == dateOnly.day)
          .map((slot) => DateTime(
                dateOnly.year,
                dateOnly.month,
                dateOnly.day,
                slot.time.hour,
                slot.time.minute,
              ))
          .toList();
    }

    if (initialSession != null &&
        initialSession!.year == dateOnly.year &&
        initialSession!.month == dateOnly.month &&
        initialSession!.day == dateOnly.day) {
      return [initialSession!];
    }

    return const [];
  }

  CourseSchedule copyWith({
    DateTime? initialSession,
    CourseRepeatPattern? repeatPattern,
    List<WeeklyCourseTime>? weeklySlots,
    List<MonthlyCourseTime>? monthlySlots,
    CourseMakeUpMethod? makeUpMethod,
  }) {
    return CourseSchedule(
      initialSession: initialSession ?? this.initialSession,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      weeklySlots: weeklySlots ?? this.weeklySlots,
      monthlySlots: monthlySlots ?? this.monthlySlots,
      makeUpMethod: makeUpMethod ?? this.makeUpMethod,
    );
  }

  DateTime? nextSession(DateTime reference) {
    final candidates = <DateTime>[];

    if (repeatPattern == CourseRepeatPattern.weekly) {
      for (final slot in weeklySlots) {
        candidates.add(slot.nextAfter(reference));
      }
    } else if (repeatPattern == CourseRepeatPattern.monthly) {
      for (final slot in monthlySlots) {
        final next = slot.nextAfter(reference);
        if (next != null) candidates.add(next);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort();
      return candidates.first;
    }

    if (initialSession != null && !initialSession!.isBefore(reference)) {
      return initialSession;
    }

    return null;
  }

  String repeatSummaryLabel({int maxItems = 3}) {
    if (repeatPattern == CourseRepeatPattern.none) return '不重复';

    if (repeatPattern == CourseRepeatPattern.weekly) {
      final items = weeklySlots.map((e) => e.formatLabel()).toList();
      if (items.isEmpty) return '按周重复（未设置）';
      final shown = items.take(maxItems).join('、');
      final suffix = items.length > maxItems ? '…' : '';
      return '按周：$shown$suffix';
    }

    final items = monthlySlots.map((e) => e.formatLabel()).toList();
    if (items.isEmpty) return '按月重复（未设置）';
    final shown = items.take(maxItems).join('、');
    final suffix = items.length > maxItems ? '…' : '';
    return '按月：$shown$suffix';
  }

  Map<String, dynamic> toJson() => {
        'initialSession': initialSession?.toIso8601String(),
        'repeatPattern': repeatPattern.name,
        'weeklySlots': weeklySlots.map((e) => e.toJson()).toList(),
        'monthlySlots': monthlySlots.map((e) => e.toJson()).toList(),
        'makeUpMethod': makeUpMethod.name,
      };

  factory CourseSchedule.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CourseSchedule();
    return CourseSchedule(
      initialSession: _parseDate(json['initialSession']),
      repeatPattern: _repeatPatternFrom(json['repeatPattern'] as String?),
      weeklySlots: (json['weeklySlots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WeeklyCourseTime.fromJson)
          .toList(),
      monthlySlots: (json['monthlySlots'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MonthlyCourseTime.fromJson)
          .toList(),
      makeUpMethod: _makeUpMethodFrom(json['makeUpMethod'] as String?),
    );
  }
}

class Course {
  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.totalLessons,
    required this.consumedLessons,
    this.lessonDurationMinutes = 60,
    this.startDate,
    this.endDate,
    this.schedule = const CourseSchedule(),
    this.attendanceRecords = const [],
  });

  final String id;
  final String title;
  final String category;
  final double totalLessons;
  final double consumedLessons;
  final int lessonDurationMinutes;
  final DateTime? startDate;
  final DateTime? endDate;
  final CourseSchedule schedule;
  final List<CourseAttendanceRecord> attendanceRecords;

  double get remainingLessons =>
      (totalLessons - consumedLessons).clamp(0, totalLessons);

  Course copyWith({
    String? id,
    String? title,
    String? category,
    double? totalLessons,
    double? consumedLessons,
    int? lessonDurationMinutes,
    DateTime? startDate,
    DateTime? endDate,
    CourseSchedule? schedule,
    List<CourseAttendanceRecord>? attendanceRecords,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      totalLessons: totalLessons ?? this.totalLessons,
      consumedLessons: consumedLessons ?? this.consumedLessons,
      lessonDurationMinutes: lessonDurationMinutes ?? this.lessonDurationMinutes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      schedule: schedule ?? this.schedule,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'totalLessons': totalLessons,
        'consumedLessons': consumedLessons,
        'lessonDurationMinutes': lessonDurationMinutes,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'schedule': schedule.toJson(),
        'attendanceRecords': attendanceRecords.map((e) => e.toJson()).toList(),
      };

  factory Course.fromJson(String id, Map<String, dynamic> json) {
    return Course(
      id: id,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      totalLessons: (json['totalLessons'] as num?)?.toDouble() ?? 0,
      consumedLessons: (json['consumedLessons'] as num?)?.toDouble() ?? 0,
      lessonDurationMinutes: (json['lessonDurationMinutes'] as num?)?.toInt() ?? 60,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      schedule: CourseSchedule.fromJson(
        json['schedule'] as Map<String, dynamic>?,
      ),
      attendanceRecords:
          (json['attendanceRecords'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(CourseAttendanceRecord.fromJson)
              .toList(),
    );
  }
}

class CourseDraft {
  const CourseDraft({
    required this.title,
    required this.category,
    required this.totalLessons,
    this.consumedLessons = 0,
    this.lessonDurationMinutes = 60,
    this.startDate,
    this.endDate,
    this.schedule = const CourseSchedule(),
  });

  final String title;
  final String category;
  final double totalLessons;
  final double consumedLessons;
  final int lessonDurationMinutes;
  final DateTime? startDate;
  final DateTime? endDate;
  final CourseSchedule schedule;
}

enum AttendanceStatus { attended, missed, leave }

class CourseAttendanceRecord {
  const CourseAttendanceRecord({
    required this.sessionStart,
    required this.status,
  });

  final DateTime sessionStart;
  final AttendanceStatus status;

  Map<String, dynamic> toJson() => {
        'sessionStart': sessionStart.toIso8601String(),
        'status': status.name,
      };

  factory CourseAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return CourseAttendanceRecord(
      sessionStart: _parseDate(json['sessionStart']) ?? DateTime.now(),
      status: _attendanceStatusFrom(json['status'] as String?),
    );
  }
}

CourseRepeatPattern _repeatPatternFrom(String? value) {
  return CourseRepeatPattern.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CourseRepeatPattern.none,
  );
}

CourseMakeUpMethod _makeUpMethodFrom(String? value) {
  return CourseMakeUpMethod.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CourseMakeUpMethod.autoPostpone,
  );
}

AttendanceStatus _attendanceStatusFrom(String? value) {
  return AttendanceStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AttendanceStatus.attended,
  );
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;  if (value is String) return DateTime.tryParse(value);
  return null;
}

