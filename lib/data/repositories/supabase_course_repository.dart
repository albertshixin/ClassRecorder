import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/course.dart';
import 'course_repository.dart';

class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository({required this.userId})
      : _client = Supabase.instance.client;

  final String userId;
  final SupabaseClient _client;

  @override
  Future<List<Course>> list() async {
    final rows = await _client
        .from('courses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_fromRow)
        .toList();
  }

  @override
  Stream<List<Course>> watch() {
    return _client
        .from('courses')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<Course> create(CourseDraft draft) async {
    final response = await _client.from('courses').insert({
      'user_id': userId,
      'title': draft.title,
      'category': draft.category,
      'total_lessons': draft.totalLessons,
      'consumed_lessons': draft.consumedLessons,
      'lesson_duration_minutes': draft.lessonDurationMinutes,
      'start_date': draft.startDate?.toIso8601String(),
      'end_date': draft.endDate?.toIso8601String(),
      'schedule': draft.schedule.toJson(),
      'attendance_records': const [],
    }).select();

    final row = (response as List).first as Map<String, dynamic>;
    return _fromRow(row);
  }

  @override
  Future<void> update(Course course) async {
    await _client.from('courses').update({
      'title': course.title,
      'category': course.category,
      'total_lessons': course.totalLessons,
      'consumed_lessons': course.consumedLessons,
      'lesson_duration_minutes': course.lessonDurationMinutes,
      'start_date': course.startDate?.toIso8601String(),
      'end_date': course.endDate?.toIso8601String(),
      'schedule': course.schedule.toJson(),
      'attendance_records': course.attendanceRecords.map((e) => e.toJson()).toList(),
    }).eq('id', course.id);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('courses').delete().eq('id', id);
  }

  Future<void> seedIfEmpty(List<Course> seed) async {
    final existing = await _client
        .from('courses')
        .select('id')
        .eq('user_id', userId)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    final rows = seed
        .map(
          (course) => {
            'user_id': userId,
            'title': course.title,
            'category': course.category,
            'total_lessons': course.totalLessons,
            'consumed_lessons': course.consumedLessons,
            'lesson_duration_minutes': course.lessonDurationMinutes,
            'start_date': course.startDate?.toIso8601String(),
            'end_date': course.endDate?.toIso8601String(),
            'schedule': course.schedule.toJson(),
            'attendance_records': course.attendanceRecords.map((e) => e.toJson()).toList(),
          },
        )
        .toList();

    await _client.from('courses').insert(rows);
  }

  Course _fromRow(Map<String, dynamic> row) {
    return Course.fromJson(
      row['id'] as String,
      {
        'title': row['title'],
        'category': row['category'],
        'totalLessons': row['total_lessons'],
        'consumedLessons': row['consumed_lessons'],
        'lessonDurationMinutes': row['lesson_duration_minutes'],
        'startDate': row['start_date'],
        'endDate': row['end_date'],
        'schedule': row['schedule'],
        'attendanceRecords': row['attendance_records'],
      },
    );
  }
}
