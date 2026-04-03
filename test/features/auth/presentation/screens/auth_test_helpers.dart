import 'dart:convert';
import 'dart:typed_data';

import 'package:eantrack/features/auth/data/auth_repository.dart';
import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(this._repo, AuthState initial) : super(_repo) {
    state = initial;
  }

  final AuthRepository _repo;

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

  @override
  Future<void> signUp(
      {required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<bool> checkEmailConfirmed() async => false;

  @override
  Future<bool> resendVerificationEmail() async => true;

  AuthRepository get repository => _repo;
}

class FakeAssetBundle extends CachingAssetBundle {
  static final ByteData _empty = ByteData.sublistView(Uint8List(0));

  @override
  Future<ByteData> load(String key) async => _empty;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('.svg')) {
      return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect width="10" height="10"/></svg>';
    }
    if (key.endsWith('.json')) {
      return jsonEncode(<String, Object>{
        'v': '5.7.1',
        'fr': 30,
        'ip': 0,
        'op': 1,
        'w': 10,
        'h': 10,
        'nm': 'empty',
        'ddd': 0,
        'assets': <Object>[],
        'layers': <Object>[],
      });
    }
    return '';
  }
}

Widget buildTestable({
  required Widget child,
  required AuthRepository repository,
  required TestAuthNotifier notifier,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authNotifierProvider.overrideWith((ref) => notifier),
    ],
    child: DefaultAssetBundle(
      bundle: FakeAssetBundle(),
      child: MaterialApp(home: child),
    ),
  );
}
