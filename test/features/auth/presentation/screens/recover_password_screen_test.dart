import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:eantrack/features/auth/presentation/screens/recover_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'auth_test_helpers.dart';

void main() {
  testWidgets('renderiza RecoverPasswordScreen sem crash', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await pumpAuthTestable(
      tester,
      child: const RecoverPasswordScreen(),
      repository: repo,
      notifier: notifier,
    );

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
  });

  testWidgets('mostra modal de sucesso apos envio bem-sucedido', (tester) async {
    final repo = MockAuthRepository();
    String? sentToEmail;
    final notifier = CallbackAuthNotifier(
      repo,
      const AuthUnauthenticated(),
      onResetPassword: (email) async {
        sentToEmail = email;
      },
    );

    await pumpAuthTestable(
      tester,
      child: const RecoverPasswordScreen(),
      repository: repo,
      notifier: notifier,
    );

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.tap(find.text('Enviar'));
    await tester.pump();
    for (var i = 0;
        i < 10 && find.text('Link enviado').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(sentToEmail, 'user@test.com');
    expect(find.text('Link enviado'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
  });

  testWidgets('mostra cooldown de reenvio quando o link ja foi enviado',
      (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await pumpAuthTestable(
      tester,
      child: const RecoverPasswordScreen(),
      repository: repo,
      notifier: notifier,
      overrides: [
        passwordRecoveryCooldownProvider.overrideWith((ref) {
          final cooldown = ResendCooldownNotifier(
            lockDuration: const Duration(minutes: 15),
          );
          cooldown.onResendSuccess();
          return cooldown;
        }),
      ],
    );

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);
    expect(find.textContaining('Reenviar em '), findsOneWidget);
  });
}
