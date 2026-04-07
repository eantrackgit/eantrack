import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:eantrack/features/auth/presentation/screens/recover_password_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

void main() {
  testWidgets('renderiza RecoverPasswordScreen sem crash', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await tester.pumpWidget(
      buildTestable(
        child: const RecoverPasswordScreen(),
        repository: repo,
        notifier: notifier,
      ),
    );

    expect(find.text('Esqueceu sua senha?'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
  });

  testWidgets('mostra cooldown de reenvio quando o link ja foi enviado',
      (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await tester.pumpWidget(
      buildTestable(
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
      ),
    );

    expect(find.text('Link enviado com sucesso'), findsOneWidget);
    expect(find.textContaining('Reenviar em '), findsOneWidget);
  });
}
