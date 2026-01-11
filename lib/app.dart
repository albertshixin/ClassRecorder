import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'data/models/course.dart';
import 'data/repositories/in_memory_course_repository.dart';
import 'providers/course_store.dart';
import 'ui/views/course/course_create_page.dart';
import 'ui/views/course/course_detail_page.dart';
import 'ui/views/home/home_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final CourseStore _store;

  @override
  void initState() {
    super.initState();
    _store = CourseStore(
      repository: InMemoryCourseRepository(
        seed: const [
          Course(
            id: 'seed-1',
            title: '雅马哈钢琴课',
            category: '音乐',
            totalLessons: 20,
            consumedLessons: 1,
            lessonDurationMinutes: 60,
          ),
          Course(
            id: 'seed-2',
            title: '少儿英语一对一',
            category: '学科',
            totalLessons: 30,
            consumedLessons: 24,
            lessonDurationMinutes: 60,
          ),
          Course(
            id: 'seed-3',
            title: '足球训练营',
            category: '运动',
            totalLessons: 12,
            consumedLessons: 10,
            lessonDurationMinutes: 60,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: _store,
      child: MaterialApp(
        title: '课管家',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1E88E5), // 蓝色科技感基准
          scaffoldBackgroundColor: const Color(0xFFF7F9FC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF7F9FC),
            foregroundColor: Color(0xFF0D47A1),
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: const Color(0xFFEEF4FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1E88E5),
              side: const BorderSide(color: Color(0xFF64B5F6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF0D47A1),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            backgroundColor: const Color(0xFFE3F2FD),
            selectedColor: const Color(0xFF1E88E5),
            labelStyle: const TextStyle(
              color: Color(0xFF0D47A1),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        routes: {
          '/': (_) => const HomePage(),
          CourseCreatePage.routeName: (_) => const CourseCreatePage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == CourseDetailPage.routeName &&
              settings.arguments is Course) {
            return MaterialPageRoute(
              builder: (_) =>
                  CourseDetailPage(course: settings.arguments as Course),
            );
          }
          return null;
        },
      ),
    );
  }
}
