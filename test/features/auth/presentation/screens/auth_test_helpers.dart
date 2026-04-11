import 'dart:convert';

import 'package:eantrack/features/auth/data/auth_repository.dart';
import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:eantrack/shared/providers/theme_provider.dart';
import 'package:eantrack/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

class CallbackAuthNotifier extends TestAuthNotifier {
  CallbackAuthNotifier(
    super.repo,
    super.initial, {
    this.onResetPassword,
  });

  final Future<void> Function(String email)? onResetPassword;

  @override
  Future<void> resetPassword(String email) async {
    await onResetPassword?.call(email);
  }
}

class FakeAssetBundle extends CachingAssetBundle {
  static final ByteData _empty = ByteData(0);

  static ByteData _byteDataFromString(String value) {
    final bytes = utf8.encode(value);
    final data = ByteData(bytes.length);
    for (var i = 0; i < bytes.length; i++) {
      data.setUint8(i, bytes[i]);
    }
    return data;
  }

  static String? _assetContents(String key) {
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
    return null;
  }

  @override
  Future<ByteData> load(String key) async {
    final contents = _assetContents(key);
    if (contents != null) {
      return _byteDataFromString(contents);
    }
    return _empty;
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _assetContents(key) ?? '';
  }
}

Widget buildTestable({
  required Widget child,
  required AuthRepository repository,
  required TestAuthNotifier notifier,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authNotifierProvider.overrideWith((ref) => notifier),
      ...overrides,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeModeProvider);

        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          home: DefaultAssetBundle(
            bundle: FakeAssetBundle(),
            child: child,
          ),
        );
      },
    ),
  );
}

Future<void> pumpAuthTestable(
  WidgetTester tester, {
  required Widget child,
  required AuthRepository repository,
  required TestAuthNotifier notifier,
  List<Override> overrides = const [],
  Size surfaceSize = const Size(1920, 3000),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    buildTestable(
      child: child,
      repository: repository,
      notifier: notifier,
      overrides: overrides,
    ),
  );
  await tester.pump();
}
