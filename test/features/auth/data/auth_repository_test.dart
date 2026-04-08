import 'dart:async';

import 'package:eantrack/core/error/app_exception.dart';
import 'package:eantrack/features/auth/data/auth_repository.dart';
import 'package:eantrack/features/auth/data/password_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPasswordHistoryService extends Mock
    implements PasswordHistoryService {}

class _FakePostgrestBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  final dynamic _value;

  _FakePostgrestBuilder(this._value);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return Future<dynamic>.value(_value).then<U>(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockPasswordHistoryService passwordHistoryService;
  late AuthRepository repository;

  const email = 'user@test.com';
  const password = 'StrongPass@1';

  final user = User(
    id: 'user-1',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-03-29T00:00:00.000Z',
    email: email,
  );

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    passwordHistoryService = MockPasswordHistoryService();
    repository = AuthRepository(
      client: client,
      passwordHistoryService: passwordHistoryService,
    );
    when(() => client.auth).thenReturn(auth);
  });

  group('signIn', () {
    test('login sucesso', () async {
      when(
        () => auth.signInWithPassword(
            email: any(named: 'email'), password: any(named: 'password')),
      ).thenAnswer((_) async => AuthResponse(user: user));

      await repository.signIn(email: email, password: password);

      verify(
        () => auth.signInWithPassword(email: email, password: password),
      ).called(1);
    });

    test('login erro', () async {
      when(
        () => auth.signInWithPassword(
            email: any(named: 'email'), password: any(named: 'password')),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => repository.signIn(email: email, password: password),
        throwsA(
          isA<AuthAppException>().having(
              (e) => e.message, 'message', 'E-mail ou senha incorretos.'),
        ),
      );
    });

    test('tratamento de excecoes', () async {
      when(
        () => auth.signInWithPassword(
            email: any(named: 'email'), password: any(named: 'password')),
      ).thenThrow(Exception('unexpected'));

      expect(
        () => repository.signIn(email: email, password: password),
        throwsA(
          isA<AuthAppException>().having(
            (e) => e.message,
            'message',
            'Erro de autenticação: Exception: unexpected',
          ),
        ),
      );
    });
  });

  test('cadastro', () async {
    when(() => client.rpc('email_code_exists', params: any(named: 'params')))
        .thenAnswer((_) => _FakePostgrestBuilder(false));
    when(
      () => auth.signUp(
          email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => AuthResponse(user: user));
    when(() => client.rpc('insert_email_code', params: any(named: 'params')))
        .thenAnswer((_) => _FakePostgrestBuilder(null));

    await repository.signUp(email: email, password: password);

    verify(() => auth.signUp(email: email, password: password)).called(1);
    verify(() => client.rpc('insert_email_code', params: any(named: 'params')))
        .called(1);
  });

  test('logout', () async {
    when(() => auth.signOut()).thenThrow(Exception('network'));

    await repository.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
