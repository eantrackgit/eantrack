import 'package:eantrack/core/error/app_exception.dart';
import 'package:eantrack/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late SupabaseClient client;
  late GoTrueClient auth;
  late AuthRepository repository;

  const email = 'user@test.com';
  const password = 'StrongPass1';

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
    repository = AuthRepository(client);
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
            'Erro ao realizar login. Tente novamente.',
          ),
        ),
      );
    });
  });

  test('cadastro', () async {
    when(() => client.rpc('email_code_exists', params: any(named: 'params')))
        .thenAnswer((_) async => false);
    when(
      () => auth.signUp(
          email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => AuthResponse(user: user));
    when(() => client.rpc('insert_email_code', params: any(named: 'params')))
        .thenAnswer((_) async => null);

    await repository.signUp(email: email, password: password);

    verify(() => auth.signUp(email: email, password: password)).called(1);
    verify(() => client.rpc('insert_email_code', params: any(named: 'params')))
        .called(1);
  });

  test('logout', () async {
    when(() => auth.signOut(scope: any(named: 'scope')))
        .thenThrow(Exception('network'));

    await repository.signOut();

    verify(() => auth.signOut(scope: any(named: 'scope'))).called(1);
  });
}
