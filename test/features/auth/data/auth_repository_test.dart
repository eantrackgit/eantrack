import 'package:eantrack/core/error/app_exception.dart';
import 'package:eantrack/features/auth/data/auth_repository.dart';
import 'package:eantrack/features/auth/data/password_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPasswordHistoryService extends Mock implements PasswordHistoryService {}

/// Fake builder that resolves to [_value] when awaited.
/// Satisfies the PostgrestFilterBuilder<dynamic> return type of rpc().
class _FakePostgrestBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakePostgrestBuilder(this._value);
  final dynamic _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic) onValue, {
    Function? onError,
  }) =>
      Future<dynamic>.value(_value).then(onValue, onError: onError);

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) =>
      Future<dynamic>.value(_value);

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) =>
      Future<dynamic>.value(_value).whenComplete(action);

  @override
  Stream<dynamic> asStream() => Stream.value(_value);

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) =>
      Future<dynamic>.value(_value).timeout(timeLimit, onTimeout: onTimeout);

  // Allow builder chaining (.select(), .eq(), etc.) without breaking the chain.
  _FakePostgrestBuilder select([String columns = '*']) => this;
}

void main() {
  late SupabaseClient client;
  late GoTrueClient auth;
  late PasswordHistoryService passwordHistoryService;
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
            'Erro ao realizar login. Tente novamente.',
          ),
        ),
      );
    });
  });

  test('cadastro', () async {
    when(() => client.rpc('email_code_exists', params: any(named: 'params')))
        .thenReturn(_FakePostgrestBuilder(false));
    when(
      () => auth.signUp(
          email: any(named: 'email'), password: any(named: 'password')),
    ).thenAnswer((_) async => AuthResponse(user: user));
    when(() => client.rpc('insert_email_code', params: any(named: 'params')))
        .thenReturn(_FakePostgrestBuilder(null));

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
