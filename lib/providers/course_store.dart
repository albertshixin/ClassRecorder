import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/course.dart';
import '../data/repositories/course_repository.dart';

class CourseStore extends ChangeNotifier {
  CourseStore({required CourseRepository repository})
      : _repository = repository {
    _subscribe();
  }

  CourseRepository _repository;
  StreamSubscription<List<Course>>? _subscription;
  List<Course> _courses = const [];

  List<Course> get courses => List.unmodifiable(_courses);

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.watch().listen((items) {
      _courses = items;
      notifyListeners();
    });
  }

  Future<void> useRepository(CourseRepository repository) async {
    _repository = repository;
    _subscribe();
    await refresh();
  }

  Future<void> refresh() async {
    _courses = await _repository.list();
    notifyListeners();
  }

  Future<Course> create(CourseDraft draft) async {
    final created = await _repository.create(draft);
    await refresh();
    return created;
  }

  Future<void> update(Course course) async {
    await _repository.update(course);
    await refresh();
  }

  Future<void> checkIn(String courseId, DateTime sessionStart,
      {bool makeUp = false}) async {
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index == -1) return;
    final course = _courses[index];

    // 已经打过卡则忽略
    final dateOnly =
        DateTime(sessionStart.year, sessionStart.month, sessionStart.day);
    final hasAttended = course.attendanceRecords.any((r) =>
        r.status == AttendanceStatus.attended &&
        r.sessionStart.year == dateOnly.year &&
        r.sessionStart.month == dateOnly.month &&
        r.sessionStart.day == dateOnly.day);
    if (hasAttended) return;

    final delta = makeUp ? -1 : 1;
    final newConsumed = (course.consumedLessons + delta)
        .clamp(0, course.totalLessons)
        .toDouble();

    final updated = course.copyWith(
      consumedLessons: newConsumed,
      attendanceRecords: _upsertAttendance(
        course.attendanceRecords,
        CourseAttendanceRecord(
          sessionStart: sessionStart,
          status: AttendanceStatus.attended,
        ),
      ),
    );

    await update(updated);
  }

  Future<void> removeCheckIn(String courseId, DateTime sessionStart) async {
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index == -1) return;
    final course = _courses[index];

    final targetDate =
        DateTime(sessionStart.year, sessionStart.month, sessionStart.day);

    final existedAttended = course.attendanceRecords.any((r) =>
        r.status == AttendanceStatus.attended &&
        r.sessionStart.year == targetDate.year &&
        r.sessionStart.month == targetDate.month &&
        r.sessionStart.day == targetDate.day);
    if (!existedAttended) return;

    final updatedRecords = course.attendanceRecords.where((r) {
      final sameDay = r.sessionStart.year == targetDate.year &&
          r.sessionStart.month == targetDate.month &&
          r.sessionStart.day == targetDate.day;
      return !(sameDay && r.status == AttendanceStatus.attended);
    }).toList();

    final newConsumed =
        (course.consumedLessons - 1).clamp(0, course.totalLessons).toDouble();

    final updated = course.copyWith(
      consumedLessons: newConsumed,
      attendanceRecords: updatedRecords,
    );
    await update(updated);
  }

  Future<void> setLeave(String courseId, DateTime sessionStart,
      {required bool leave}) async {
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index == -1) return;
    final course = _courses[index];

    List<CourseAttendanceRecord> nextRecords;
    if (leave) {
      nextRecords = _upsertAttendance(
        course.attendanceRecords,
        CourseAttendanceRecord(
          sessionStart: sessionStart,
          status: AttendanceStatus.leave,
        ),
      );
    } else {
      // 取消请假：移除该天的请假记录
      nextRecords = course.attendanceRecords.where((r) {
        final sameDay = r.sessionStart.year == sessionStart.year &&
            r.sessionStart.month == sessionStart.month &&
            r.sessionStart.day == sessionStart.day;
        return !(sameDay && r.status == AttendanceStatus.leave);
      }).toList();
    }

    final updated = course.copyWith(attendanceRecords: nextRecords);
    await update(updated);
  }

  List<CourseAttendanceRecord> _upsertAttendance(
    List<CourseAttendanceRecord> list,
    CourseAttendanceRecord record,
  ) {
    final sameDay = (CourseAttendanceRecord r) =>
        r.sessionStart.year == record.sessionStart.year &&
        r.sessionStart.month == record.sessionStart.month &&
        r.sessionStart.day == record.sessionStart.day;

    final filtered = list.where((r) => !sameDay(r)).toList();
    return [...filtered, record];
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await refresh();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
