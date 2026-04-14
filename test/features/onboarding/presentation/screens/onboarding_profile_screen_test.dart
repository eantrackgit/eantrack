import 'package:eantrack/core/error/app_exception.dart';
import 'package:eantrack/core/router/app_routes.dart';
import 'package:eantrack/features/onboarding/data/onboarding_repository.dart';
import 'package:eantrack/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:eantrack/features/onboarding/presentation/screens/onboarding_profile_screen.dart';
import 'package:eantrack/shared/providers/theme_provider.dart';
import 'package:eantrack/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

Finder _textFieldByHint(String hintText) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.hintText == hintText,
    description: 'TextField com hint "$hintText"',
  );
}

Finder get _nameField => _textFieldByHint('Digite seu nome completo');
Finder get _descriptionField => find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.maxLines == 3 &&
          widget.maxLength == 200,
      description: 'TextField de descricao',
    );
Finder get _identifierField =>
    _textFieldByHint('Escolha seu identificador');

const _advanceLabel = 'Avan\u00E7ar';
const _shortSuggestionsTitle = 'Sugest\u00F5es para voc\u00EA';
const _availableText = 'Identificador dispon\u00EDvel!';
const _takenText =
    'Esse identificador n\u00E3o est\u00E1 dispon\u00EDvel.';
const _takenSuggestionsTitle =
    'Outras op\u00E7\u00F5es dispon\u00EDveis';

void main() {
  late MockOnboardingRepository repository;

  setUp(() {
    repository = MockOnboardingRepository();
    when(() => repository.identificadorExiste(any()))
        .thenAnswer((_) async => false);
    when(
      () => repository.reservarIdentificadorComCadastro(any(), any()),
    ).thenAnswer((_) async => true);
    when(() => repository.updateDescricao(any())).thenAnswer((_) async {});
  });

  Future<GoRouter> pumpScreen(
    WidgetTester tester, {
    String mode = 'agency',
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.onboardingIndividual,
      routes: [
        GoRoute(
          path: AppRoutes.onboardingIndividual,
          builder: (_, __) => OnboardingProfileScreen(mode: mode),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const Scaffold(body: Text('Back destination')),
        ),
        GoRoute(
          path: AppRoutes.onboardingCnpj,
          builder: (_, __) => const Scaffold(body: Text('CNPJ destination')),
        ),
        GoRoute(
          path: AppRoutes.hub,
          builder: (_, __) => const Scaffold(body: Text('Hub destination')),
        ),
      ],
    );

    tester.view.physicalSize = const Size(1440, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      router.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);

            return MaterialApp.router(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  Future<void> enterAvailableIdentifier(
    WidgetTester tester, {
    String name = 'Joao Silva',
    String identifier = 'clientebase1',
  }) async {
    await tester.enterText(_nameField, name);
    await tester.enterText(_identifierField, identifier);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  testWidgets('nome obrigatorio mantem avancar desabilitado ate preencher',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(_identifierField, 'clientebase1');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, _advanceLabel),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('contador de descricao acompanha digitacao', (tester) async {
    await pumpScreen(tester);

    expect(find.text('0/200'), findsOneWidget);

    await tester.enterText(_descriptionField, 'abc');
    await tester.pump();

    expect(find.text('3/200'), findsOneWidget);
  });

  testWidgets('identificador com menos de 10 caracteres nao consulta RPC',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(_identifierField, 'curto123');
    await tester.pump();

    expect(find.text('Analisando identificador...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    verifyNever(() => repository.identificadorExiste(any()));
    expect(find.text('M\u00EDnimo de 10 caracteres.'), findsOneWidget);
    expect(find.text(_shortSuggestionsTitle), findsOneWidget);
    expect(find.text('curto123oficial'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('identificador curto prioriza sugestoes pelo nome preenchido',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(_nameField, 'Joao Silva');
    await tester.enterText(_identifierField, 'curto123');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    verifyNever(() => repository.identificadorExiste(any()));
    expect(find.text(_shortSuggestionsTitle), findsOneWidget);
    expect(find.text('joaosilva'), findsOneWidget);
    expect(find.text('curto123oficial'), findsNothing);
  });

  testWidgets('identificador disponivel exibe check', (tester) async {
    await pumpScreen(tester);

    await enterAvailableIdentifier(tester);

    expect(find.text(_availableText), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    verify(() => repository.identificadorExiste('clientebase1')).called(1);
  });

  testWidgets('identificador ocupado exibe sugestoes', (tester) async {
    when(() => repository.identificadorExiste(any()))
        .thenAnswer((invocation) async {
      final value = invocation.positionalArguments.first as String;
      if (value == 'clientebase1') return true;
      return false;
    });

    await pumpScreen(tester);
    await tester.enterText(_nameField, 'Joao Silva');
    await tester.enterText(_identifierField, 'clientebase1');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text(_takenText), findsOneWidget);
    expect(find.text(_takenSuggestionsTitle), findsOneWidget);
    expect(find.text('joaosilva'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text(_availableText), findsNothing);
  });

  testWidgets(
      'identificador existente normalizado nao reaproveita estado disponivel',
      (tester) async {
    when(() => repository.identificadorExiste(any()))
        .thenAnswer((invocation) async {
      final value = invocation.positionalArguments.first as String;
      if (value == 'adminteste') return true;
      return false;
    });

    await pumpScreen(tester);

    await tester.enterText(_nameField, 'Marcio Jose');
    await tester.enterText(_identifierField, 'clientebase1');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text(_availableText), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.enterText(_identifierField, '@AdminTeste ');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    verify(() => repository.identificadorExiste('adminteste')).called(1);
    expect(find.text(_takenText), findsOneWidget);
    expect(find.text(_availableText), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('clique em sugestao preenche campo', (tester) async {
    when(() => repository.identificadorExiste(any()))
        .thenAnswer((invocation) async {
      final value = invocation.positionalArguments.first as String;
      if (value == 'clientebase1') return true;
      return false;
    });

    await pumpScreen(tester);
    await tester.enterText(_nameField, 'Joao Silva');
    await tester.enterText(_identifierField, 'clientebase1');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.text('joaosilva'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('joaosilva'), findsWidgets);
    expect(find.text(_availableText), findsOneWidget);
  });

  testWidgets('botao avancar chama fluxo final corretamente', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(_descriptionField, 'Especialista em operacoes');
    await enterAvailableIdentifier(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, _advanceLabel));
    await tester.pump();
    await tester.pump();

    verify(
      () => repository.reservarIdentificadorComCadastro(
        'clientebase1',
        'Joao Silva',
      ),
    ).called(1);
    verify(
      () => repository.updateDescricao('Especialista em operacoes'),
    ).called(1);
    expect(find.text('CNPJ destination'), findsOneWidget);
  });

  testWidgets('nao navega em caso de falha de identificador ocupado',
      (tester) async {
    var originalChecks = 0;
    when(() => repository.identificadorExiste(any()))
        .thenAnswer((invocation) async {
      final value = invocation.positionalArguments.first as String;
      if (value == 'clientebase1') {
        originalChecks++;
        return originalChecks > 1;
      }
      return false;
    });
    when(
      () => repository.reservarIdentificadorComCadastro(any(), any()),
    ).thenAnswer((_) async => false);

    await pumpScreen(tester);
    await enterAvailableIdentifier(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, _advanceLabel));
    await tester.pump();
    await tester.pump();

    expect(find.text('CNPJ destination'), findsNothing);
    expect(find.text(_takenSuggestionsTitle), findsOneWidget);
    expect(find.text(_takenText), findsOneWidget);
  });

  testWidgets('conflito 23505 no submit volta identificador para ocupado',
      (tester) async {
    when(() => repository.identificadorExiste(any()))
        .thenAnswer((invocation) async {
      final value = invocation.positionalArguments.first as String;
      return value == 'adminteste';
    });
    when(
      () => repository.reservarIdentificadorComCadastro(any(), any()),
    ).thenThrow(
      const ServerException(
        'Nao foi possivel concluir o cadastro complementar. (23505)',
      ),
    );

    await pumpScreen(tester);
    await tester.enterText(_nameField, 'Marcio Jose');
    await tester.enterText(_identifierField, 'adminteste');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text(_takenText), findsOneWidget);
    expect(find.text(_availableText), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });
}
