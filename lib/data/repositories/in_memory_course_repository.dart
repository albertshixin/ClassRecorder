import 'dart:async';

import '../models/course.dart';
import 'course_repository.dart';

class InMemoryCourseRepository implements CourseRepository {
  InMemoryCourseRepository({List<Course>? seed}) : _items = [...?seed] {
    _emit();
  }

  final List<Course> _items;
  final StreamController<List<Course>> _controller =
      StreamController<List<Course>>.broadcast();
  int _nextId = 1;

  void _emit() {
    _controller.add(List.unmodifiable(_items));
  }

  @override
  Future<List<Course>> list() async => List.unmodifiable(_items);

  @override
  Stream<List<Course>> watch() => _controller.stream;

  @override
  Future<Course> create(CourseDraft draft) async {
    final course = Course(
      id: (_nextId++).toString(),
      title: draft.title,
      category: draft.category,
      totalLessons: draft.totalLessons,
      consumedLessons: draft.consumedLessons,
      lessonDurationMinutes: draft.lessonDurationMinutes,
      startDate: draft.startDate,
      endDate: draft.endDate,
      schedule: draft.schedule,
      attendanceRecords: const [],
    );
    _items.insert(0, course);
    _emit();
    return course;
  }

  @override
  Future<void> update(Course course) async {
    final index = _items.indexWhere((c) => c.id == course.id);
    if (index == -1) return;
    _items[index] = course;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((c) => c.id == id);
    _emit();
  }
}
