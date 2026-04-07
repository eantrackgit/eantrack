import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

void main() {
  testWidgets('renderiza EmailVerificationScreen sem crash', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(
      repo,
      const AuthEmailUnconfirmed(email: 'user@test.com'),
    );

    await tester.pumpWidget(
      buildTestable(
        child: const EmailVerificationScreen(),
        repository: repo,
        notifier: notifier,
      ),
    );

    expect(find.text('Confirme sua conta'), findsOneWidget);
    expect(find.text('Reenviar'), findsOneWidget);
  });
}
