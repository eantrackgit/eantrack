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

/// Avança o debounce (350 ms) e drena os futures resultantes.
Future<void> _pumpDebounce(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // normalize — método estático puro, sem Timer
  // -------------------------------------------------------------------------

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

    test('remove caracteres invalidos e mantém a-z 0-9 . _ -', () {
      expect(
        IdentifierController.normalize('João!#\$%silva.pro'),
        'joaosilva.pro',
      );
    });

    test('mantém . _ - validos', () {
      expect(
        IdentifierController.normalize('joao.silva_pro-01'),
        'joao.silva_pro-01',
      );
    });

    test('entrada com apenas chars invalidos retorna vazia', () {
      expect(IdentifierController.normalize('!!!###'), '');
    });
  });

  // -------------------------------------------------------------------------
  // Estado inicial
  // -------------------------------------------------------------------------

  group('estado inicial', () {
    test('status idle, sem mensagem, sem sugestões, sem confirmado', () {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      expect(ctrl.status, IdentifierStatus.idle);
      expect(ctrl.message, isNull);
      expect(ctrl.suggestions, isEmpty);
      expect(ctrl.confirmedAvailable, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // onChanged — entrada vazia
  // -------------------------------------------------------------------------

  group('onChanged — vazio', () {
    testWidgets('entrada vazia retorna ao estado idle', (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      // coloca em estado intermediário primeiro
      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);
      expect(ctrl.status, IdentifierStatus.available);

      // apaga
      ctrl.onChanged('');
      await tester.pump();

      expect(ctrl.status, IdentifierStatus.idle);
      expect(ctrl.message, isNull);
      expect(ctrl.suggestions, isEmpty);
      expect(ctrl.confirmedAvailable, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // onChanged — identificador curto (< 10 chars)
  // -------------------------------------------------------------------------

  group('onChanged — identificador curto (< 10 chars)', () {
    testWidgets('exibe typing imediatamente, tooShort apos debounce',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.onChanged('curto123');

      // imediato: typing
      expect(ctrl.status, IdentifierStatus.typing);
      expect(ctrl.message, 'Analisando identificador...');

      await _pumpDebounce(tester);

      // após debounce: tooShort, sem chamar checkExists
      expect(ctrl.status, IdentifierStatus.tooShort);
      expect(ctrl.message, 'Identificador não disponível.');
      expect(checkCalls, 0);
    });

    testWidgets('gera sugestões locais sem chamar checkExists', (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.onChanged('curto123');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      expect(ctrl.suggestions, isNotEmpty);
      expect(ctrl.suggestions.length, lessThanOrEqualTo(5));
      expect(checkCalls, 0);
    });

    testWidgets(
        'sugestões baseadas no nome quando nome está preenchido',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      ctrl.onChanged('curto123');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.tooShort);
      // deve incluir sugestão baseada no nome (joaosilva)
      expect(ctrl.suggestions.any((s) => s.contains('joao')), isTrue);
    });

    testWidgets('sugestões baseadas no identificador quando sem nome',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.onChanged('curto123');
      await _pumpDebounce(tester);

      // sem nome: sugestões geradas a partir do identificador
      expect(ctrl.suggestions, isNotEmpty);
      expect(ctrl.suggestions.any((s) => s.contains('oficial')), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // onChanged — identificador válido (>= 10 chars)
  // -------------------------------------------------------------------------

  group('onChanged — identificador válido (>= 10 chars)', () {
    testWidgets('disponível: status available e confirmedAvailable setado',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      expect(ctrl.status, IdentifierStatus.checking);

      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.message, 'Identificador disponível!');
      expect(ctrl.confirmedAvailable, 'clientebase1');
      expect(ctrl.suggestions, isEmpty);
    });

    testWidgets('ocupado: status taken com sugestões', (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.message, 'Esse identificador não está disponível.');
      expect(ctrl.confirmedAvailable, isNull);
      expect(ctrl.suggestions, isNotEmpty);
    });

    testWidgets('normaliza entrada antes de checar (@, maiúsculas, espaços)',
        (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.onChanged('@AdminTeste ');
      await _pumpDebounce(tester);

      // deve ter consultado o valor normalizado
      expect(checked, contains('adminteste'));
      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.textController.text, 'adminteste');
    });

    testWidgets('AppException → status error com mensagem do exception',
        (tester) async {
      final ctrl = _make(
        checkExists: (_) async =>
            throw const ServerException('Falha de conexão ao verificar.'),
      );
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.error);
      expect(ctrl.message, 'Falha de conexão ao verificar.');
      expect(ctrl.confirmedAvailable, isNull);
    });

    testWidgets('exceção genérica → status error com mensagem padrão',
        (tester) async {
      final ctrl = _make(
        checkExists: (_) async => throw Exception('qualquer coisa'),
      );
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.error);
      expect(
        ctrl.message,
        'Não foi possível verificar o identificador agora.',
      );
    });

    testWidgets('notifica onStateChanged em cada transição', (tester) async {
      int calls = 0;
      final ctrl = _make(
        checkExists: (_) async => false,
        onStateChanged: () => calls++,
      );
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1'); // checking
      final afterChecking = calls;
      await _pumpDebounce(tester); // available

      expect(afterChecking, greaterThanOrEqualTo(1));
      expect(calls, greaterThan(afterChecking));
    });
  });

  // -------------------------------------------------------------------------
  // onChanged — controle de concorrência (race condition)
  // -------------------------------------------------------------------------

  group('onChanged — controle de concorrência', () {
    testWidgets('digitação rápida: apenas a última consulta é aplicada',
        (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      // primeira digitação — debounce ainda pendente
      ctrl.onChanged('primeiro123');
      // segunda digitação — cancela a primeira
      ctrl.onChanged('clientebase1');

      await _pumpDebounce(tester);

      // apenas o último identificador foi consultado
      expect(checked, isNot(contains('primeiro123')));
      expect(checked, contains('clientebase1'));
      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.confirmedAvailable, 'clientebase1');
    });

    testWidgets(
        'novo onChanged durante async invalida resultado anterior',
        (tester) async {
      int calls = 0;
      final ctrl = _make(checkExists: (id) async {
        calls++;
        return false;
      });
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await tester.pump(const Duration(milliseconds: 400)); // timer fires
      // antes do Future resolver, inicia novo ciclo
      ctrl.onChanged('outrobase999');
      await _pumpDebounce(tester);

      // confirmedAvailable deve ser do último identificador
      expect(ctrl.confirmedAvailable, 'outrobase999');
      expect(ctrl.status, IdentifierStatus.available);
    });
  });

  // -------------------------------------------------------------------------
  // onNameChanged
  // -------------------------------------------------------------------------

  group('onNameChanged', () {
    testWidgets(
        'quando tooShort: atualiza sugestões locais com base no nome',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      ctrl.onChanged('curto123');
      await _pumpDebounce(tester);
      expect(ctrl.status, IdentifierStatus.tooShort);
      final suggestionsAntes = List<String>.from(ctrl.suggestions);

      // define nome e notifica o controller
      ctrl.onNameChanged('Maria Santos');
      await tester.pump();

      // sugestões devem refletir o nome
      final suggestionsDepois = ctrl.suggestions;
      expect(suggestionsDepois.any((s) => s.contains('maria')), isTrue);
      // e serem diferentes das anteriores (que eram baseadas no identificador)
      expect(suggestionsDepois, isNot(equals(suggestionsAntes)));
    });

    testWidgets(
        'quando taken: agenda revalidação com refresh de sugestões',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (id) async {
        checkCalls++;
        return id == 'clientebase1'; // sempre tomado
      });
      addTearDown(ctrl.dispose);

      // coloca em taken
      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);
      expect(ctrl.status, IdentifierStatus.taken);

      // simula identificador com 10+ chars que é taken
      ctrl.onChanged('clientebase2');
      await _pumpDebounce(tester);
      final checkCallsAposPrimeiroTaken = checkCalls;

      // muda o nome enquanto taken — deve reagendar validação
      ctrl.onNameChanged('Novo Nome');
      await _pumpDebounce(tester);

      // checkExists deve ter sido chamado novamente (para sugestões com novo nome)
      expect(checkCalls, greaterThan(checkCallsAposPrimeiroTaken));
    });

    testWidgets('quando idle: não dispara validação', (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });
      addTearDown(ctrl.dispose);

      // sem nada digitado
      ctrl.onNameChanged('Joao Silva');
      await _pumpDebounce(tester);

      expect(checkCalls, 0);
      expect(ctrl.status, IdentifierStatus.idle);
    });
  });

  // -------------------------------------------------------------------------
  // applySuggestion
  // -------------------------------------------------------------------------

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
      await tester.pump();

      expect(ctrl.textController.text, 'joaosilva01');
      expect(checked, contains('joaosilva01'));
    });

    testWidgets('normaliza sugestão antes de aplicar', (tester) async {
      final checked = <String>[];
      final ctrl = _make(checkExists: (id) async {
        checked.add(id);
        return false;
      });
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('@Joao.Silva01 ');
      await tester.pump();

      expect(ctrl.textController.text, 'joao.silva01');
      expect(checked, contains('joao.silva01'));
    });

    testWidgets('torna disponível quando checkExists retorna false',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => false);
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('joaosilva01');
      await tester.pump();

      expect(ctrl.status, IdentifierStatus.available);
      expect(ctrl.confirmedAvailable, 'joaosilva01');
    });

    testWidgets('permanece taken quando checkExists retorna true',
        (tester) async {
      final ctrl = _make(checkExists: (_) async => true);
      addTearDown(ctrl.dispose);

      await ctrl.applySuggestion('joaosilva01');
      await tester.pump();

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.confirmedAvailable, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // applyTakenStateFromConflict
  // -------------------------------------------------------------------------

  group('applyTakenStateFromConflict', () {
    testWidgets('define taken com mensagem e sugestões', (tester) async {
      final ctrl = _make(checkExists: (id) async {
        // só o identificador principal é tomado; sugestões estão livres
        return id == 'clientebase1';
      });
      addTearDown(ctrl.dispose);

      // prepara o textController para que a checagem de texto funcione
      ctrl.textController.text = 'clientebase1';

      await ctrl.applyTakenStateFromConflict('clientebase1');

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.message, 'Esse identificador não está disponível.');
      expect(ctrl.confirmedAvailable, isNull);
      expect(ctrl.suggestions, isNotEmpty);
    });

    testWidgets('gera sugestões disponíveis (checkExists false) nas sugestões',
        (tester) async {
      final ctrl = _make(checkExists: (id) async {
        return id == 'clientebase1'; // apenas o principal é tomado
      });
      addTearDown(ctrl.dispose);

      ctrl.textController.text = 'clientebase1';
      await ctrl.applyTakenStateFromConflict('clientebase1');

      // todas as sugestões devem ser identificadores livres
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

      // inicia o conflito mas muda o identificador antes de completar
      final future = ctrl.applyTakenStateFromConflict('clientebase1');
      ctrl.textController.text = 'outroidentif';

      await future;

      // resultado deve ser ignorado pois o texto mudou
      expect(ctrl.status, isNot(IdentifierStatus.taken));
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose', () {
    testWidgets('cancela debounce pendente (checkExists não chamado)',
        (tester) async {
      int checkCalls = 0;
      final ctrl = _make(checkExists: (_) async {
        checkCalls++;
        return false;
      });

      ctrl.onChanged('clientebase1'); // agenda debounce
      ctrl.dispose(); // cancela antes de disparar

      await tester.pump(const Duration(milliseconds: 400));

      expect(checkCalls, 0);
    });

    testWidgets('onStateChanged não é chamado após dispose', (tester) async {
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

      // qualquer async pendente não deve chamar onStateChanged
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(callsAposDispose, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Geração de sugestões — contratos
  // -------------------------------------------------------------------------

  group('sugestões', () {
    testWidgets('máximo de 5 sugestões geradas', (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.suggestions.length, lessThanOrEqualTo(5));
    });

    testWidgets('sugestões não contêm o identificador original', (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);

      expect(ctrl.status, IdentifierStatus.taken);
      expect(ctrl.suggestions, isNot(contains('clientebase1')));
    });

    testWidgets('todas as sugestões seguem o formato normalizado',
        (tester) async {
      final ctrl = _make(checkExists: (id) async => id == 'clientebase1');
      addTearDown(ctrl.dispose);

      ctrl.onNameChanged('Joao Silva');
      ctrl.onChanged('clientebase1');
      await _pumpDebounce(tester);

      for (final s in ctrl.suggestions) {
        // deve ser idempotente na normalização
        expect(IdentifierController.normalize(s), s);
      }
    });
  });
}
