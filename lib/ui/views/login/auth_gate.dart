import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/app_scope.dart';
import '../../../data/demo_courses.dart';
import '../../../data/repositories/in_memory_course_repository.dart';
import '../../../data/repositories/supabase_course_repository.dart';
import '../../../data/repositories/supabase_profile_repository.dart';
import '../home/home_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _activeUid;
  Future<void>? _setupFuture;

  Future<void> _setupForUser(User user) async {
    final store = AppScope.of(context);
    final profileRepo = SupabaseProfileRepository(userId: user.id);
    await profileRepo.upsertFromAuth(user);

    final repo = SupabaseCourseRepository(userId: user.id);
    await repo.seedIfEmpty(kDemoCourses);
    await store.useRepository(repo);
  }

  void _resetStore() {
    if (_activeUid == null) return;
    _activeUid = null;
    _setupFuture = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = AppScope.of(context);
      store.useRepository(InMemoryCourseRepository());
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = auth.currentSession;
        final user = session?.user;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        if (user == null) {
          _resetStore();
          return const LoginPage();
        }

        if (_activeUid != user.id) {
          _activeUid = user.id;
          _setupFuture = _setupForUser(user);
        }

        return FutureBuilder<void>(
          future: _setupFuture,
          builder: (context, setupSnapshot) {
            if (setupSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            if (setupSnapshot.hasError) {
              return _ErrorScreen(
                message:
                    '登录初始化失败，请重试。\n${setupSnapshot.error ?? ''}'.trim(),
                onRetry: () {
                  setState(() {
                    _activeUid = null;
                    _setupFuture = null;
                  });
                },
              );
            }
            return const HomePage();
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
