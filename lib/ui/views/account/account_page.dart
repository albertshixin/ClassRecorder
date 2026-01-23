import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/supabase_profile_repository.dart';
import '../login/login_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const routeName = '/account';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('账号与安全')),
        body: _LoggedOutSection(onLoginTap: () {
          Navigator.of(context).pushNamed(LoginPage.routeName);
        }),
      );
    }

    final repo = SupabaseProfileRepository(userId: user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账号与安全'),
      ),
      body: StreamBuilder<UserProfile>(
        stream: repo.watch(),
        builder: (context, snapshot) {
          final profile = snapshot.data ??
              UserProfile(
                id: user.id,
                displayName: user.userMetadata?['full_name'] as String?,
                email: user.email,
                phone: user.phone,
                photoUrl: user.userMetadata?['avatar_url'] as String?,
                provider: user.appMetadata['provider'] as String?,
              );

          final displayName = profile.displayName ?? '未命名用户';
          final photoUrl = profile.photoUrl;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                            photoUrl == null ? null : NetworkImage(photoUrl),
                        child: photoUrl == null
                            ? Text(
                                displayName.characters.take(1).toString(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '登录方式：${_providerLabel(profile.provider)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BindTile(
                icon: Icons.mail_outline,
                title: '邮箱',
                value: profile.email,
                onTap: () async {
                  final value = await _promptForValue(
                    context,
                    title: '绑定邮箱',
                    hint: '请输入邮箱',
                    initialValue: profile.email,
                  );
                  if (value != null && value.isNotEmpty) {
                    await repo.updateEmail(value);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('邮箱绑定成功')),
                    );
                  }
                },
              ),
              _BindTile(
                icon: Icons.phone_iphone,
                title: '手机号',
                value: profile.phone,
                onTap: () async {
                  final value = await _promptForValue(
                    context,
                    title: '绑定手机号',
                    hint: '请输入手机号',
                    keyboardType: TextInputType.phone,
                    initialValue: profile.phone,
                  );
                  if (value != null && value.isNotEmpty) {
                    await repo.updatePhone(value);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('手机号绑定成功')),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已退出登录')),
                  );
                  Navigator.of(context)
                      .pushReplacementNamed(LoginPage.routeName);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('退出登录'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoggedOutSection extends StatelessWidget {
  const _LoggedOutSection({required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '还未登录',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '登录后可同步课程、绑定邮箱和手机号',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onLoginTap,
              child: const Text('去登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BindTile extends StatelessWidget {
  const _BindTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bound = value != null && value!.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          bound ? value! : '未绑定',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(bound ? '修改' : '绑定'),
        ),
      ),
    );
  }
}

String _providerLabel(String? providerId) {
  switch (providerId) {
    case 'google':
      return 'Google';
    case 'apple':
      return 'Apple';
    default:
      return providerId ?? '未知';
  }
}

Future<String?> _promptForValue(
  BuildContext context, {
  required String title,
  required String hint,
  TextInputType keyboardType = TextInputType.text,
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue ?? '');
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确认'),
          ),
        ],
      );
    },
  );
}
