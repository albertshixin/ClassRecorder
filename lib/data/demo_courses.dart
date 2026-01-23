import 'models/course.dart';

final List<Course> kDemoCourses = [
  Course(
    id: 'demo-1',
    title: '高一数学冲刺班',
    category: '学科辅导',
    totalLessons: 24,
    consumedLessons: 6,
    lessonDurationMinutes: 90,
    startDate: DateTime(2026, 1, 15),
    schedule: CourseSchedule(
      repeatPattern: CourseRepeatPattern.weekly,
      weeklySlots: [
        WeeklyCourseTime(
          weekday: DateTime.tuesday,
          time: ClassTimeOfDay(hour: 19, minute: 0),
        ),
        WeeklyCourseTime(
          weekday: DateTime.friday,
          time: ClassTimeOfDay(hour: 19, minute: 0),
        ),
      ],
    ),
  ),
  Course(
    id: 'demo-2',
    title: '创意美术素养',
    category: '艺术素养',
    totalLessons: 16,
    consumedLessons: 3,
    lessonDurationMinutes: 75,
    startDate: DateTime(2025, 12, 20),
    schedule: CourseSchedule(
      repeatPattern: CourseRepeatPattern.weekly,
      weeklySlots: [
        WeeklyCourseTime(
          weekday: DateTime.saturday,
          time: ClassTimeOfDay(hour: 10, minute: 0),
        ),
      ],
    ),
  ),
  Course(
    id: 'demo-3',
    title: '青少年足球体能',
    category: '体育训练',
    totalLessons: 18,
    consumedLessons: 12,
    lessonDurationMinutes: 90,
    startDate: DateTime(2025, 11, 5),
    schedule: CourseSchedule(
      repeatPattern: CourseRepeatPattern.weekly,
      weeklySlots: [
        WeeklyCourseTime(
          weekday: DateTime.wednesday,
          time: ClassTimeOfDay(hour: 17, minute: 30),
        ),
        WeeklyCourseTime(
          weekday: DateTime.sunday,
          time: ClassTimeOfDay(hour: 9, minute: 0),
        ),
      ],
    ),
  ),
  Course(
    id: 'demo-4',
    title: 'Python 少儿编程',
    category: '科技编程',
    totalLessons: 20,
    consumedLessons: 5,
    lessonDurationMinutes: 80,
    startDate: DateTime(2026, 1, 10),
    schedule: CourseSchedule(
      repeatPattern: CourseRepeatPattern.weekly,
      weeklySlots: [
        WeeklyCourseTime(
          weekday: DateTime.saturday,
          time: ClassTimeOfDay(hour: 14, minute: 0),
        ),
      ],
    ),
  ),
  Course(
    id: 'demo-5',
    title: '思维与领导力',
    category: '综合素养',
    totalLessons: 12,
    consumedLessons: 2,
    lessonDurationMinutes: 70,
    startDate: DateTime(2026, 2, 1),
    schedule: CourseSchedule(
      repeatPattern: CourseRepeatPattern.weekly,
      weeklySlots: [
        WeeklyCourseTime(
          weekday: DateTime.monday,
          time: ClassTimeOfDay(hour: 18, minute: 30),
        ),
      ],
    ),
  ),
  Course(
    id: 'demo-6',
    title: '少儿日语口语',
    category: '语言文化',
    totalLessons: 15,
    consumedLessons: 4,
    lessonDurationMinutes: 60,
    startDate: DateTime(2026, 1, 8),
    schedule: CourseSchedule(
      repeatPattern: CourseRepeatPattern.weekly,
      weeklySlots: [
        WeeklyCourseTime(
          weekday: DateTime.thursday,
          time: ClassTimeOfDay(hour: 16, minute: 0),
        ),
      ],
    ),
  ),
];
