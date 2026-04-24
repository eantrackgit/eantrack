import 'package:eantrack/core/router/app_routes.dart';
import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:eantrack/features/auth/presentation/screens/login_screen.dart';
import 'package:eantrack/shared/providers/theme_provider.dart';
import 'package:eantrack/shared/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_test_helpers.dart';

void main() {
  Future<void> _pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renderiza LoginScreen sem crash', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await pumpAuthTestable(
      tester,
      child: const LoginScreen(),
      repository: repo,
      notifier: notifier,
    );

    expect(find.text('Entrar'), findsOneWidget);
    expect(
      find.textContaining('Esqueceu sua senha?', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Smart Tracking'), findsOneWidget);
    expect(find.text('Testar Validade'), findsOneWidget);
    verifyNever(() => repo.signIn(
        email: any(named: 'email'), password: any(named: 'password')));
  });

  testWidgets(
      'mostra banner de recovery quando email digitado corresponde ao email enviado',
      (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await pumpAuthTestable(
      tester,
      child: const LoginScreen(
        notice: LoginScreenNotice.recoveryEmailSent,
      ),
      repository: repo,
      notifier: notifier,
      overrides: [
        passwordRecoveryCooldownProvider.overrideWith((ref) {
          final cooldown = ResendCooldownNotifier(
            lockDuration: const Duration(minutes: 15),
          );
          cooldown.onResendSuccess(email: 'user@test.com');
          return cooldown;
        }),
      ],
    );

    await tester.enterText(find.byType(TextFormField).first, 'USER@test.com');
    await tester.pump();

    expect(find.textContaining('Enviamos o link de recupera'), findsOneWidget);
  });

  testWidgets(
      'nao mostra banner de recovery quando email digitado nao corresponde',
      (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await pumpAuthTestable(
      tester,
      child: const LoginScreen(
        notice: LoginScreenNotice.recoveryEmailSent,
      ),
      repository: repo,
      notifier: notifier,
      overrides: [
        passwordRecoveryCooldownProvider.overrideWith((ref) {
          final cooldown = ResendCooldownNotifier(
            lockDuration: const Duration(minutes: 15),
          );
          cooldown.onResendSuccess(email: 'user@test.com');
          return cooldown;
        }),
      ],
    );

    await tester.enterText(find.byType(TextFormField).first, 'other@test.com');
    await tester.pump();

    expect(find.textContaining('Enviamos o link de recupera'), findsNothing);
  });

  testWidgets('botao de teste navega para a tela de validade', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());
    final router = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.validity,
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Tela de validade')),
          ),
        ),
      ],
    );

    tester.view.physicalSize = const Size(1920, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      router.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          authNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return DefaultAssetBundle(
              bundle: FakeAssetBundle(),
              child: MaterialApp.router(
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeMode,
                routerConfig: router,
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Testar Validade'));
    await _pumpUi(tester);

    expect(find.text('Tela de validade'), findsOneWidget);
  });
}
