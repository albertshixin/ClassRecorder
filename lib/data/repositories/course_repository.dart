import '../models/course.dart';

abstract class CourseRepository {
  Future<List<Course>> list();
  Stream<List<Course>> watch();
  Future<Course> create(CourseDraft draft);
  Future<void> update(Course course);
  Future<void> delete(String id);
}
