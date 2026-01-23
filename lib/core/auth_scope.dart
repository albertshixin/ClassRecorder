import 'package:flutter/widgets.dart';

import '../providers/auth_store.dart';

class AuthScope extends InheritedNotifier<AuthStore> {
  const AuthScope({
    super.key,
    required AuthStore auth,
    required Widget child,
  }) : super(notifier: auth, child: child);

  static AuthStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope not found. Wrap MaterialApp with AuthScope.');
    return scope!.notifier!;
  }
}
