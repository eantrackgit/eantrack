import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/presentation/screens/register_screen.dart';
import 'package:eantrack/shared/widgets/password_rule_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test_helpers.dart';

Finder _ruleRow(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(PasswordRuleRow));

Finder _fieldByHint(String hint) => find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && widget.decoration?.hintText == hint,
      description: 'TextFormField with hint "$hint"',
    );

void main() {
  testWidgets('renderiza RegisterScreen sem crash', (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await tester.pumpWidget(
      buildTestable(
        child: const RegisterScreen(),
        repository: repo,
        notifier: notifier,
      ),
    );

    expect(find.text('Crie sua conta'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets(
      'mantem "As senhas coincidem" como ultimo item do checklist no mesmo grupo visual',
      (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await tester.pumpWidget(
      buildTestable(
        child: const RegisterScreen(),
        repository: repo,
        notifier: notifier,
      ),
    );

    const labels = [
      'Uma letra mai\u00fascula',
      'Uma letra min\u00fascula',
      'Um n\u00famero',
      'M\u00ednimo de 8 caracteres',
      'Um s\u00edmbolo (ex: @, #, \$, %, &, *)',
      'As senhas coincidem',
    ];

    expect(find.byType(PasswordRuleRow), findsNWidgets(6));

    var lastY = -1.0;
    for (final label in labels) {
      final currentY = tester.getTopLeft(find.text(label)).dy;
      expect(currentY, greaterThan(lastY), reason: 'ordem incorreta para $label');
      lastY = currentY;
    }

    final confirmRuleY = tester.getTopLeft(find.text('As senhas coincidem')).dy;
    final confirmFieldY = tester.getTopLeft(find.text('Confirmar senha')).dy;

    expect(confirmRuleY, lessThan(confirmFieldY));
  });

  testWidgets(
      'deixa a regra de confirmacao neutra vazia e satisfeita quando as senhas coincidem',
      (tester) async {
    final repo = MockAuthRepository();
    final notifier = TestAuthNotifier(repo, const AuthUnauthenticated());

    await tester.pumpWidget(
      buildTestable(
        child: const RegisterScreen(),
        repository: repo,
        notifier: notifier,
      ),
    );

    final matchRow = _ruleRow('As senhas coincidem');

    expect(
      find.descendant(
        of: matchRow,
        matching: find.byIcon(Icons.radio_button_unchecked),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: matchRow,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );

    await tester.enterText(_fieldByHint('Digite sua senha'), 'Senha@123');
    await tester.pump();

    expect(
      find.descendant(
        of: matchRow,
        matching: find.byIcon(Icons.radio_button_unchecked),
      ),
      findsOneWidget,
    );

    await tester.enterText(_fieldByHint('Repita a senha'), 'Senha@123');
    await tester.pump();

    expect(
      find.descendant(
        of: matchRow,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });
}
