import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_test_helpers.dart';

void main() {
  testWidgets('renderiza LoginScreen sem crash', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await tester.pumpWidget(
      buildTestable(
        child: const LoginScreen(),
        repository: repo,
        notifier: notifier,
      ),
    );

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Esqueceu a senha?'), findsOneWidget);
    verifyNever(() => repo.signIn(
        email: any(named: 'email'), password: any(named: 'password')));
  });
}
