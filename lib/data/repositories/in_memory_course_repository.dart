import '../models/course.dart';
import 'course_repository.dart';

class InMemoryCourseRepository implements CourseRepository {
  InMemoryCourseRepository({List<Course>? seed}) : _items = [...?seed];

  final List<Course> _items;
  int _nextId = 1;

  @override
  List<Course> list() => List.unmodifiable(_items);

  @override
  Course create(CourseDraft draft) {
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
    return course;
  }

  @override
  void update(Course course) {
    final index = _items.indexWhere((c) => c.id == course.id);
    if (index == -1) return;
    _items[index] = course;
  }

  @override
  void delete(String id) {
    _items.removeWhere((c) => c.id == id);
  }
}
