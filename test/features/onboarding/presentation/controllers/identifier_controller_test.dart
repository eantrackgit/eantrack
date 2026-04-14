import 'dart:async';

import 'package:eantrack/core/error/app_exception.dart';
import 'package:eantrack/features/onboarding/presentation/controllers/identifier_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

IdentifierController _make({
  required Future<bool> Function(String) checkExists,
  VoidCallback? onStateChanged,
}) {
  return IdentifierController(
    checkExists: checkExists,
    onStateChanged: onStateChanged ?? () {},
  );
}

Future<void> _pumpDebounce(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _pumpDebounceAndAsync(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  group('normalize', () {
    test('string vazia retorna vazia', () {
      expect(IdentifierController.normalize(''), '');
    });

    test('remove espacos e converte para minusculo', () {
      expect(IdentifierController.normalize('  Joao Silva  '), 'joaosilva');
    });

    test('remove @', () {
      expect(IdentifierController.normalize('@joao'), 'joao');
    });

    test('remove caracteres invalidos e mantem a-z 0-9 . _ -', () {
      expect(
        IdentifierController.normalize('João!#\$%silva.pro'),
        'joaosilva.pro',
      );
    });

    test('mantem . _ - validos', () {
      expect(
        IdentifierController.normalize('joao.silva_pro-01'),
        'joao.silva_pro-01',
      );
    });

    test('entrada com apenas chars invalidos retorna vazia', () {
      expect(IdentifierController.normalize('!!!###'), '');
    });
  });

  group('estado inicial', () {
    test('status idle, sem mensagem, sem sugestoes, sem confirmado', () {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      expect(ctrl.status, IdentifierStatus.idle);
      expect(ctrl.message, isNull);
      expect(ctrl.suggestions, isEmpty);
      expect(ctrl.confirmedAvailable, isNull);
    });
  });

  group('onChanged - vazio', () {
    testWidgets('entrada vazia retorna ao estado idle', (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);
      expect(ctrl.status, IdentifierStatus.available);

      ctrl.textController.text = '';
      ctrl.onChanged('');
      await tester.pump();

      expect(ctrl.status, IdentifierStatus.idle);
      expect(ctrl.message, isNull);
      expect(ctrl.suggestions, isEmpty);
      expect(ctrl.confirmedAvailable, isNull);
    });
  });

  group('onChanged - identificador curto (< 10 chars)', () {
    testWidgets('exibe typing imediatamente, tooShort apos debounce',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'curto123';
      ctrl.onChanged('curto123');
      expect(ctrl.status, IdentifierStatus.typing);

      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      expect(ctrl.message, 'M\u00EDnimo de 10 caracteres.');
      expect(checkCalls, 0);
    });

    testWidgets('gera sugestoes locais sem chamar checkExists',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'curto123';
      ctrl.onChanged('curto123');
      expect(ctrl.status, IdentifierStatus.typing);

      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      expect(ctrl.suggestions, isNotEmpty);
      expect(ctrl.suggestions.length, lessThanOrEqualTo(5));
      expect(checkCalls, 0);
    });

    testWidgets('sugestoes baseadas no nome quando nome esta preenchido',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      ctrl.textController.text = 'curto123';
      ctrl.onChanged('curto123');
      expect(ctrl.status, IdentifierStatus.typing);

      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      expect(ctrl.suggestions.any((s) => s.contains('joao')), isTrue);
    });

    testWidgets('sugestoes baseadas no identificador quando sem nome',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'curto123';
      ctrl.onChanged('curto123');
      expect(ctrl.status, IdentifierStatus.typing);

      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      expect(ctrl.suggestions, isNotEmpty);
      expect(ctrl.suggestions.any((s) => s.contains('oficial')), isTrue);
    });
  });

  group('onChanged - identificador valido (>= 10 chars)', () {
    testWidgets('disponivel: status available e confirmedAvailable setado',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.message, 'Identificador dispon\u00EDvel!');
      expect(ctrl.confirmedAvailable, 'clientebase1');
      expect(ctrl.suggestions, isEmpty);
    });

    testWidgets('ocupado: status taken com sugestoes', (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(
        ctrl.message,
        'Esse identificador n\u00E3o est\u00E1 dispon\u00EDvel.',
      );
      expect(ctrl.confirmedAvailable, isNull);
      expect(ctrl.suggestions, isNotEmpty);
    });

    testWidgets('normaliza entrada antes de checar (@, maiusculas, espacos)',
        (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.onChanged('@AdminTeste ');
      await _pumpDebounceAndAsync(tester);

      expect(checked, contains('adminteste'));
      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.textController.text, 'adminteste');
    });

    testWidgets('AppException -> status error com mensagem do exception',
        (tester) async {
      final ctrl = _make(
        checkExists: (_) async =>
            throw const ServerException('Falha de conex\u00E3o ao verificar.'),
      );
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(ctrl.status, IdentifierStatus.error);
      expect(ctrl.message, 'Falha de conex\u00E3o ao verificar.');
      expect(ctrl.confirmedAvailable, isNull);
    });

    testWidgets('excecao generica -> status error com mensagem padrao',
        (tester) async {
      final ctrl = _make(
        checkExists: (_) async => throw Exception('qualquer coisa'),
      );
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(ctrl.status, IdentifierStatus.error);
      expect(
        ctrl.message,
        'N\u00E3o foi poss\u00EDvel verificar o identificador agora.',
      );
    });

    testWidgets('notifica onStateChanged em cada transicao', (tester) async {
      int calls = 0;
      final ctrl = _make(
        checkExists: (_) async => false,
        onStateChanged: () => calls++,
      );
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(calls, greaterThanOrEqualTo(1));
    });
  });

  group('onChanged - controle de concorrencia', () {
    testWidgets('digitacao rapida: apenas a ultima consulta e aplicada',
        (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'primeiro123';
      ctrl.onChanged('primeiro123');
      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');

      await _pumpDebounceAndAsync(tester);

      expect(checked, isNot(contains('primeiro123')));
      expect(checked, contains('clientebase1'));
      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.confirmedAvailable, 'clientebase1');
    });

    testWidgets('novo onChanged durante async invalida resultado anterior',
        (tester) async {
      final checked = <String>[];
      final firstCheck = Completer<bool>();
      final secondCheck = Completer<bool>();

      final ctrl = _make(checkExists: (id) {
        checked.add(id);
        if (id == 'clientebase1') return firstCheck.future;
        if (id == 'outrobase999') return secondCheck.future;
        return Future.value(false);
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(checked, contains('clientebase1'));
      expect(ctrl.status, IdentifierStatus.checking);

      ctrl.textController.text = 'outrobase999';
      ctrl.onChanged('outrobase999');
      await _pumpDebounceAndAsync(tester);

      expect(checked, contains('outrobase999'));
      expect(ctrl.status, IdentifierStatus.checking);

      firstCheck.complete(false);
      await tester.pump();

      expect(ctrl.status, IdentifierStatus.checking);
      expect(ctrl.confirmedAvailable, isNull);

      secondCheck.complete(false);
      await tester.pump();
      await tester.pump();

      expect(ctrl.confirmedAvailable, 'outrobase999');
      expect(ctrl.status, IdentifierStatus.available);
    });
  });

  group('onNameChanged', () {
    testWidgets('quando tooShort: atualiza sugestoes locais com base no nome',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'curto123';
      ctrl.onChanged('curto123');
      expect(ctrl.status, IdentifierStatus.typing);

      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      final suggestionsAntes = List<String>.from(ctrl.suggestions);

      ctrl.onNameChanged('Maria Santos');
      await tester.pump();

      final suggestionsDepois = ctrl.suggestions;
      expect(suggestionsDepois.any((s) => s.contains('maria')), isTrue);
      expect(suggestionsDepois, isNot(equals(suggestionsAntes)));
    });

    testWidgets('quando taken: agenda revalidacao com refresh de sugestoes',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (id) async {
        checkCalls++;
        return id == 'clientebase1';
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);
      expect(ctrl.status, IdentifierStatus.taken);

      final checkCallsAposPrimeiroTaken = checkCalls;

      ctrl.onNameChanged('Novo Nome');
      await _pumpDebounceAndAsync(tester);

      expect(checkCalls, greaterThan(checkCallsAposPrimeiroTaken));
    });

      testWidgets('quando idle: nao dispara validacao', (tester) async {
        int checkCalls = 0;
        final ctrl = _make(checkExists: (_) async {
          checkCalls++;
          return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      await _pumpDebounce(tester);

        expect(checkCalls, 0);
        expect(ctrl.status, IdentifierStatus.idle);
      });

      testWidgets('quando available: nao altera estado', (tester) async {
        int checkCalls = 0;
        final ctrl = _make(checkExists: (_) async {
          checkCalls++;
          return false;
        });
        addTearDown(ctrl.dispose);

        ctrl.textController.text = 'clientebase1';
        ctrl.onChanged('clientebase1');
        await _pumpDebounceAndAsync(tester);

        expect(ctrl.status, IdentifierStatus.available);
        expect(ctrl.confirmedAvailable, 'clientebase1');
        final callsAntes = checkCalls;

        ctrl.onNameChanged('Novo Nome');
        await tester.pump();

        expect(ctrl.status, IdentifierStatus.available);
        expect(ctrl.confirmedAvailable, 'clientebase1');
        expect(checkCalls, callsAntes);
      });

      testWidgets('quando checking: nao interfere no fluxo', (tester) async {
        final checked = <String>[];
        final checkCompleter = Completer<bool>();
        final ctrl = _make(checkExists: (id) {
          checked.add(id);
          return checkCompleter.future;
        });
        addTearDown(ctrl.dispose);

        ctrl.textController.text = 'clientebase1';
        ctrl.onChanged('clientebase1');
        await _pumpDebounceAndAsync(tester);

        expect(ctrl.status, IdentifierStatus.checking);
        expect(checked, ['clientebase1']);

        ctrl.onNameChanged('Novo Nome');
        await tester.pump();

        expect(ctrl.status, IdentifierStatus.checking);
        expect(checked, ['clientebase1']);

        checkCompleter.complete(false);
        await tester.pump();
        await tester.pump();

        expect(ctrl.status, IdentifierStatus.available);
        expect(ctrl.confirmedAvailable, 'clientebase1');
      });

      testWidgets('quando error: mantem erro ate nova digitacao',
          (tester) async {
        int checkCalls = 0;
        final ctrl = _make(checkExists: (_) async {
          checkCalls++;
          if (checkCalls == 1) {
            throw const ServerException('Falha de conex\u00E3o ao verificar.');
          }
          return false;
        });
        addTearDown(ctrl.dispose);

        ctrl.textController.text = 'clientebase1';
        ctrl.onChanged('clientebase1');
        await _pumpDebounceAndAsync(tester);

        expect(ctrl.status, IdentifierStatus.error);
        expect(ctrl.message, 'Falha de conex\u00E3o ao verificar.');

        ctrl.onNameChanged('Novo Nome');
        await tester.pump();

        expect(ctrl.status, IdentifierStatus.error);
        expect(ctrl.message, 'Falha de conex\u00E3o ao verificar.');

        ctrl.textController.text = 'outrobase999';
        ctrl.onChanged('outrobase999');

        expect(ctrl.status, IdentifierStatus.checking);

        await _pumpDebounceAndAsync(tester);

        expect(ctrl.status, IdentifierStatus.available);
        expect(ctrl.confirmedAvailable, 'outrobase999');
      });
    });

  group('applySuggestion', () {
    testWidgets('preenche textController e verifica disponibilidade',
        (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('joaosilva01');
      await _pumpDebounce(tester);

      expect(ctrl.textController.text, 'joaosilva01');
      expect(checked, contains('joaosilva01'));
    });

    testWidgets('normaliza sugestao antes de aplicar', (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('@Joao.Silva01 ');
      await _pumpDebounce(tester);

      expect(ctrl.textController.text, 'joao.silva01');
      expect(checked, contains('joao.silva01'));
    });

    testWidgets('torna disponivel quando checkExists retorna false',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('joaosilva01');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.confirmedAvailable, 'joaosilva01');
    });

    testWidgets('permanece taken quando checkExists retorna true',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => true);
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('joaosilva01');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.confirmedAvailable, isNull);
    });
  });

  group('applyTakenStateFromConflict', () {
    testWidgets('define taken com mensagem e sugestoes', (tester) async {
      final ctrl = _make(checkExists: (id) async {
        return id == 'clientebase1';
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';

      await ctrl.applyTakenStateFromConflict('clientebase1');

      expect(ctrl.status, IdentifierStatus.taken);
      expect(
        ctrl.message,
        'Esse identificador n\u00E3o est\u00E1 dispon\u00EDvel.',
      );
      expect(ctrl.confirmedAvailable, isNull);
      expect(ctrl.suggestions, isNotEmpty);
    });

    testWidgets('gera sugestoes disponiveis (checkExists false) nas sugestoes',
        (tester) async {
      final ctrl = _make(checkExists: (id) async {
        return id == 'clientebase1';
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      await ctrl.applyTakenStateFromConflict('clientebase1');

      for (final s in ctrl.suggestions) {
        expect(s, isNot(equals('clientebase1')));
      }
      expect(ctrl.suggestions, isNotEmpty);
    });

    testWidgets('ignora resultado se identificador mudou durante o await',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';

      final future = ctrl.applyTakenStateFromConflict('clientebase1');
      ctrl.textController.text = 'outroidentif';

      await future;

      expect(ctrl.status, isNot(IdentifierStatus.taken));
    });
  });

  group('dispose', () {
    testWidgets('cancela debounce pendente (checkExists nao chamado)',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });

      ctrl.onChanged('clientebase1');
      ctrl.dispose();

      await tester.pump(const Duration(milliseconds: 400));

      expect(checkCalls, 0);
    });

    testWidgets('onStateChanged nao e chamado apos dispose', (tester) async {
      int callsAposDispose = 0;
      bool disposed = false;

      final ctrl = _make(
        checkExists: (_) async => false,
        onStateChanged: () {
          if (disposed) callsAposDispose++;
        },
      );

      ctrl.onChanged('clientebase1');
      await tester.pump(const Duration(milliseconds: 400));

      disposed = true;
      ctrl.dispose();

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(callsAposDispose, 0);
    });
  });

  group('sugestoes', () {
    testWidgets('maximo de 5 sugestoes geradas', (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.suggestions.length, lessThanOrEqualTo(5));
    });

    testWidgets('sugestoes nao contem o identificador original',
        (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.suggestions, isNot(contains('clientebase1')));
    });

    testWidgets('todas as sugestoes seguem o formato normalizado',
        (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      ctrl.textController.text = 'clientebase1';
      ctrl.onChanged('clientebase1');
      await _pumpDebounceAndAsync(tester);

      for (final s in ctrl.suggestions) {
        expect(IdentifierController.normalize(s), s);
      }
    });
  });
}
