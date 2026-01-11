class Course {
  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.totalLessons,
    required this.consumedLessons,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String title;
  final String category;
  final double totalLessons;
  final double consumedLessons;
  final DateTime? startDate;
  final DateTime? endDate;

  double get remainingLessons =>
      (totalLessons - consumedLessons).clamp(0, totalLessons);

  Course copyWith({
    String? id,
    String? title,
    String? category,
    double? totalLessons,
    double? consumedLessons,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      totalLessons: totalLessons ?? this.totalLessons,
      consumedLessons: consumedLessons ?? this.consumedLessons,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class CourseDraft {
  const CourseDraft({
    required this.title,
    required this.category,
    required this.totalLessons,
    this.consumedLessons = 0,
    this.startDate,
    this.endDate,
  });

  final String title;
  final String category;
  final double totalLessons;
  final double consumedLessons;
  final DateTime? startDate;
  final DateTime? endDate;
}
