import 'package:eantrack/core/connectivity/connectivity_provider.dart';
import 'package:eantrack/core/connectivity/connectivity_service.dart';
import 'package:eantrack/core/router/app_router.dart';
import 'package:eantrack/core/router/app_routes.dart';
import 'package:eantrack/features/auth/domain/auth_flow_state.dart';
import 'package:eantrack/features/auth/domain/auth_state.dart';
import 'package:eantrack/features/auth/domain/user_flow_state.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:eantrack/features/hub/presentation/screens/hub_screen.dart';
import 'package:eantrack/features/onboarding/agency/controllers/agency_status_notifier.dart';
import 'package:eantrack/features/onboarding/agency/repositories/agency_status_repository.dart';
import 'package:eantrack/features/onboarding/agency/screens/agency_status_screen.dart';
import 'package:eantrack/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../auth/presentation/screens/auth_test_helpers.dart';

class _MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class _MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

class _AlwaysOnlineConnectivityService implements ConnectivityService {
  const _AlwaysOnlineConnectivityService();

  @override
  Future<bool> hasInternet() async => true;

  @override
  Stream<void> get onConnectivityChanged => const Stream<void>.empty();
}

class _SmokeAgencyStatusNotifier extends AgencyStatusNotifier {
  _SmokeAgencyStatusNotifier(AgencyStatusData data)
      : super(_MockSupabaseClient()) {
    state = AgencyStatusState(
      status: AgencyStatusLoading.success,
      data: data,
    );
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<bool> acceptTermsAndContinue({
    String termsVersion = AgencyStatusRepository.currentTermsVersion,
  }) async {
    final data = state.data;
    if (data == null) return false;

    state = state.copyWith(
      status: AgencyStatusLoading.success,
      data: data.copyWith(
        termsAccepted: true,
        termsAcceptedAt: DateTime(2026, 4, 27),
        termsVersion: termsVersion,
      ),
      isAcceptingTerms: false,
    );
    return true;
  }
}

void main() {
  testWidgets('pending agency stays on status screen', (tester) async {
    await _pumpRouterAtHub(
      tester,
      _agencyData(status: AgencyDocumentStatus.pending),
    );

    expect(find.byType(AgencyStatusScreen), findsOneWidget);
    expect(find.byType(HubScreen), findsNothing);
  });

  testWidgets('rejected agency stays on status screen', (tester) async {
    await _pumpRouterAtHub(
      tester,
      _agencyData(status: AgencyDocumentStatus.rejected),
    );

    expect(find.byType(AgencyStatusScreen), findsOneWidget);
    expect(find.byType(HubScreen), findsNothing);
  });

  testWidgets('approved agency without terms cannot enter hub', (tester) async {
    await _pumpRouterAtHub(
      tester,
      _agencyData(
        status: AgencyDocumentStatus.approved,
        termsAccepted: false,
      ),
    );

    expect(find.byType(AgencyStatusScreen), findsOneWidget);
    expect(find.byType(HubScreen), findsNothing);
  });

  testWidgets('approved agency with terms enters hub', (tester) async {
    await _pumpRouterAtHub(
      tester,
      _agencyData(
        status: AgencyDocumentStatus.approved,
        termsAccepted: true,
      ),
    );

    expect(find.byType(HubScreen), findsOneWidget);
    expect(find.byType(AgencyStatusScreen), findsNothing);
    expect(find.text('Maria Silva'), findsWidgets);
    expect(find.text('Empresa Teste LTDA'), findsWidgets);
  });

  testWidgets('AgencyStatusScreen opens scrollable terms dialog',
      (tester) async {
    final data = _agencyData(
      status: AgencyDocumentStatus.approved,
      termsAccepted: false,
    );

    await pumpAuthTestable(
      tester,
      child: const AgencyStatusScreen(),
      repository: MockAuthRepository(),
      notifier: TestAuthNotifier(
        MockAuthRepository(),
        _agencyAuthState(),
      ),
      overrides: [_agencyStatusOverride(data)],
    );

    final cta = find.textContaining('Aceitar termos').first;
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('Aceite dos termos'), findsOneWidget);
    expect(find.byType(Scrollbar), findsWidgets);
    expect(find.textContaining('plano contratado'), findsOneWidget);
  });

  testWidgets('HubScreen renders real user and agency data', (tester) async {
    await pumpAuthTestable(
      tester,
      child: const HubScreen(),
      repository: MockAuthRepository(),
      notifier: TestAuthNotifier(
        MockAuthRepository(),
        _agencyAuthState(),
      ),
      overrides: [
        _agencyStatusOverride(
          _agencyData(
            status: AgencyDocumentStatus.approved,
            termsAccepted: true,
          ),
        ),
      ],
    );

    expect(find.byType(HubScreen), findsOneWidget);
    expect(find.text('Maria Silva'), findsWidgets);
    expect(find.text('Empresa Teste LTDA'), findsWidgets);
  });
}

Future<void> _pumpRouterAtHub(
  WidgetTester tester,
  AgencyStatusData data,
) async {
  late GoRouter router;

  tester.view.physicalSize = const Size(1366, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: _routerOverrides(data),
      child: DefaultAssetBundle(
        bundle: FakeAssetBundle(),
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              routerConfig: router,
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();

  router.go(AppRoutes.hub);
  await tester.pumpAndSettle();
}

List<Override> _routerOverrides(AgencyStatusData data) {
  final repository = MockAuthRepository();
  final notifier = TestAuthNotifier(repository, _agencyAuthState());

  return [
    connectivityServiceProvider.overrideWithValue(
      const _AlwaysOnlineConnectivityService(),
    ),
    authRepositoryProvider.overrideWithValue(repository),
    authNotifierProvider.overrideWith((ref) => notifier),
    authFlowStateProvider.overrideWithValue(AuthFlowState.onboardingRequired),
    authUserStreamProvider.overrideWith((ref) => const Stream.empty()),
    authRecoveryContextProvider.overrideWith((ref) {
      final client = _MockSupabaseClient();
      final auth = _MockGoTrueClient();
      when(() => client.auth).thenReturn(auth);
      when(() => auth.onAuthStateChange).thenAnswer(
        (_) => const Stream<supabase.AuthState>.empty(),
      );
      return AuthRecoveryContextNotifier(client);
    }),
    _agencyStatusOverride(data),
  ];
}

Override _agencyStatusOverride(AgencyStatusData data) {
  return agencyStatusProvider(null).overrideWith(
    (ref) => _SmokeAgencyStatusNotifier(data),
  );
}

AuthState _agencyAuthState() {
  return AuthAuthenticated(
    user: supabase.User(
      id: 'user-1',
      appMetadata: const {},
      userMetadata: const {'cargo': 'Gestora'},
      aud: 'authenticated',
      createdAt: '2026-04-22T00:00:00.000Z',
    ),
    flowState: const UserFlowState(
      userId: 'user-1',
      hasProfile: true,
      userMode: 'agencia',
      nome: 'Maria Silva',
      agencyId: 'agency-1',
      hasLegalRepresentative: true,
    ),
  );
}

AgencyStatusData _agencyData({
  required AgencyDocumentStatus status,
  bool termsAccepted = false,
}) {
  return AgencyStatusData(
    agencyId: 'agency-1',
    agencyLegalName: 'Empresa Teste LTDA',
    statusAgency: status,
    agencyUpdatedAt: DateTime(2026, 4, 22, 10, 30),
    representativeName: 'Maria Silva',
    representativeEmail: 'maria@empresa.com.br',
    legalRepresentativeId: 'rep-1',
    representativePhone: '(11) 98765-4321',
    representativeCpf: '529.982.247-25',
    representativeRole: 'Diretora',
    documentType: 'RG',
    consolidatedDocumentStatus: status,
    rejectionReason:
        status == AgencyDocumentStatus.rejected ? 'Documento ilegivel' : null,
    termsAccepted: termsAccepted,
    termsAcceptedAt: termsAccepted ? DateTime(2026, 4, 27) : null,
    termsVersion: termsAccepted ? AgencyStatusRepository.currentTermsVersion : null,
  );
}
