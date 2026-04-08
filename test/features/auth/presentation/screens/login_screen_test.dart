import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:eantrack/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';

import 'auth_test_helpers.dart';

void main() {
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
}
