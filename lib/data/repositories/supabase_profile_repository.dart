import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.phone,
    this.photoUrl,
    this.provider,
  });

  final String id;
  final String? displayName;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? provider;
}

class SupabaseProfileRepository {
  SupabaseProfileRepository({required this.userId})
      : _client = Supabase.instance.client;

  final String userId;
  final SupabaseClient _client;

  Stream<UserProfile> watch() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
      if (rows.isEmpty) {
        return UserProfile(id: userId);
      }
      return _fromRow(rows.first);
    });
  }

  Future<void> upsertFromAuth(User user) async {
    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': user.userMetadata?['full_name'] ?? user.email,
      'email': user.email,
      'phone': user.phone,
      'photo_url': user.userMetadata?['avatar_url'],
      'provider': user.appMetadata['provider'],
    });
  }

  Future<void> updateEmail(String email) async {
    await _client.from('profiles').update({
      'email': email,
    }).eq('id', userId);
  }

  Future<void> updatePhone(String phone) async {
    await _client.from('profiles').update({
      'phone': phone,
    }).eq('id', userId);
  }

  UserProfile _fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String?,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      photoUrl: row['photo_url'] as String?,
      provider: row['provider'] as String?,
    );
  }
}
