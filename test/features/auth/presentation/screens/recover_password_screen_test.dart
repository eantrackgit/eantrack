import 'package:eantrack/features/auth/domain/auth_state.dart';
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
}
