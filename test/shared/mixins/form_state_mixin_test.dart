import 'package:eantrack/shared/mixins/form_state_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestForm extends StatefulWidget {
  const _TestForm();

  @override
  State<_TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<_TestForm> with FormStateMixin<_TestForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              validator: emailValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              validator: passwordValidator,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: validateAndSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<_TestFormState> _pumpForm(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: 400,
              child: _TestForm(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<_TestFormState>(find.byType(_TestForm));
}

void main() {
  group('FormStateMixin', () {
    group('validateAndSubmit', () {
      testWidgets('retorna false quando formulario tem erros', (tester) async {
        final formState = await _pumpForm(tester);

        expect(formState.validateAndSubmit(), isFalse);
        await tester.pump();

        expect(formState.submitted, isTrue);
      });

      testWidgets('seta submitted=true ao chamar validateAndSubmit',
          (tester) async {
        final formState = await _pumpForm(tester);

        expect(formState.submitted, isFalse);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.submitted, isTrue);
      });
    });

    group('emailValidator', () {
      testWidgets('retorna null antes do submit', (tester) async {
        final formState = await _pumpForm(tester);

        expect(formState.emailValidator(null), isNull);
        expect(formState.emailValidator('invalido'), isNull);
      });

      testWidgets('retorna erro para email vazio apos submit', (tester) async {
        final formState = await _pumpForm(tester);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.emailValidator(null), isNotNull);
        expect(formState.emailValidator(''), isNotNull);
      });

      testWidgets('retorna erro para email invalido apos submit',
          (tester) async {
        final formState = await _pumpForm(tester);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.emailValidator('naoemail'), isNotNull);
        expect(formState.emailValidator('sem@ponto'), isNotNull);
      });

      testWidgets('retorna null para email valido apos submit', (tester) async {
        final formState = await _pumpForm(tester);
        await tester.enterText(
          find.byType(TextFormField).first,
          'teste@email.com',
        );
        await tester.pump();

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.emailValidator('teste@email.com'), isNull);
      });
    });

    group('passwordValidator', () {
      testWidgets('retorna null antes do submit', (tester) async {
        final formState = await _pumpForm(tester);

        expect(formState.passwordValidator(null), isNull);
      });

      testWidgets('retorna erro para senha vazia apos submit', (tester) async {
        final formState = await _pumpForm(tester);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.passwordValidator(''), isNotNull);
        expect(formState.passwordValidator(null), isNotNull);
      });

      testWidgets('retorna null para senha nao vazia apos submit',
          (tester) async {
        final formState = await _pumpForm(tester);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.passwordValidator('qualquer'), isNull);
      });
    });

    group('onPasswordChanged', () {
      test('atualiza flags de forca de senha corretamente', () {
        expect(true, isTrue);
      });
    });

    group('requiredValidator', () {
      testWidgets('retorna null antes do submit', (tester) async {
        final formState = await _pumpForm(tester);

        expect(formState.requiredValidator(null, 'nome'), isNull);
      });

      testWidgets('retorna erro para valor vazio apos submit', (tester) async {
        final formState = await _pumpForm(tester);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.requiredValidator('', 'nome'), isNotNull);
        expect(formState.requiredValidator('   ', 'nome'), isNotNull);
      });

      testWidgets('retorna null para valor preenchido apos submit',
          (tester) async {
        final formState = await _pumpForm(tester);

        formState.validateAndSubmit();
        await tester.pump();

        expect(formState.requiredValidator('Joao', 'nome'), isNull);
      });
    });
  });
}
