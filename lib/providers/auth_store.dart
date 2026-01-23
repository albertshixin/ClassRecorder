import 'package:flutter/foundation.dart';

class AuthStore extends ChangeNotifier {
  bool signedIn = false;
  String? displayName;
  String? email;
  String? phone;
  String? provider;

  void signInWithProvider(String providerName) {
    signedIn = true;
    provider = providerName;
    displayName = displayName ?? '新用户';
    notifyListeners();
  }

  void updateDisplayName(String name) {
    displayName = name;
    notifyListeners();
  }

  void bindEmail(String value) {
    email = value;
    notifyListeners();
  }

  void bindPhone(String value) {
    phone = value;
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    provider = null;
    // 保留邮箱/手机号便于下次使用；若不需要可清空
    notifyListeners();
  }
}
