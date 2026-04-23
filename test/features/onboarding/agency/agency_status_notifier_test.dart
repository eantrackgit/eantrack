import 'dart:async';

import 'package:eantrack/features/onboarding/agency/controllers/agency_status_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class _FakeStatusQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeStatusQueryBuilder(this._filterBuilder);

  final _FakeStatusFilterBuilder _filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _filterBuilder;
  }
}

class _FakeStatusFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeStatusFilterBuilder({
    Map<String, dynamic>? data,
    Object? error,
  })  : _data = data,
        _error = error;

  final Map<String, dynamic>? _data;
  final Object? _error;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap> single() {
    return _FakeStatusTransformBuilder(data: _data, error: _error);
  }
}

class _FakeStatusTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap> {
  _FakeStatusTransformBuilder({
    Map<String, dynamic>? data,
    Object? error,
  })  : _data = data,
        _error = error;

  final Map<String, dynamic>? _data;
  final Object? _error;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap value) onValue, {
    Function? onError,
  }) {
    final error = _error;
    if (error != null) {
      return Future<PostgrestMap>.error(error).then<S>(
        onValue,
        onError: onError,
      );
    }

    return Future<PostgrestMap>.value(
      Map<String, dynamic>.from(_data ?? {}),
    ).then<S>(onValue, onError: onError);
  }
}

ProviderContainer _makeContainer({
  required SupabaseClient client,
  AgencyDocumentStatus? mockStatus,
}) {
  final container = ProviderContainer(
    overrides: [
      agencyStatusProvider(mockStatus).overrideWith((ref) {
        return AgencyStatusNotifier(
          client,
          mockStatus: mockStatus,
        );
      }),
    ],
  );
  container.listen(agencyStatusProvider(mockStatus), (_, __) {});
  return container;
}

AgencyStatusState _readState(
  ProviderContainer container, {
  AgencyDocumentStatus? mockStatus,
}) {
  return container.read(agencyStatusProvider(mockStatus));
}

AgencyStatusNotifier _readNotifier(
  ProviderContainer container, {
  AgencyDocumentStatus? mockStatus,
}) {
  return container.read(agencyStatusProvider(mockStatus).notifier);
}

User _user(String id) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-04-22T00:00:00.000Z',
  );
}

Map<String, dynamic> _statusJson({
  String statusAgency = 'pending',
  String consolidatedDocumentStatus = 'pending',
}) {
  return {
    'agency_legal_name': 'Empresa Teste LTDA',
    'status_agency': statusAgency,
    'agency_updated_at': '2026-04-22T10:30:00.000Z',
    'representative_name': 'Maria Silva',
    'representative_email': 'maria@empresa.com.br',
    'representative_phone': '11987654321',
    'representative_cpf': '52998224725',
    'document_front_url': 'https://example.com/front.png',
    'document_back_url': 'https://example.com/back.png',
    'document_type': 'RG',
    'consolidated_document_status': consolidatedDocumentStatus,
    'rejection_reason': statusAgency == 'rejected' ? 'Documento ilegivel' : null,
  };
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenAnswer((_) => auth);
  });

  test('userId == null retorna mock pending', () async {
    when(() => auth.currentUser).thenAnswer((_) => null);

    final container = _makeContainer(client: client);
    addTearDown(container.dispose);

    await _readNotifier(container).load();

    final state = _readState(container);
    expect(state.status, AgencyStatusLoading.success);
    expect(state.error, isNull);
    expect(state.data, isNotNull);
    expect(state.data!.agencyLegalName, 'Agência não vinculada');
    expect(state.data!.consolidatedDocumentStatus, AgencyDocumentStatus.pending);
    verifyNever(() => client.from(any()));
  });

  test('load bem-sucedido define estado loaded com dados da view', () async {
    when(() => auth.currentUser).thenAnswer((_) => _user('user-1'));
    final queryBuilder = _FakeStatusQueryBuilder(
      _FakeStatusFilterBuilder(data: _statusJson()),
    );
    when(() => client.from('v_user_agency_onboarding_context'))
        .thenAnswer((_) => queryBuilder);

    final container = _makeContainer(client: client);
    addTearDown(container.dispose);

    await _readNotifier(container).load();

    final state = _readState(container);
    expect(state.status, AgencyStatusLoading.success);
    expect(state.error, isNull);
    expect(state.data!.agencyLegalName, 'Empresa Teste LTDA');
    expect(state.data!.representativeName, 'Maria Silva');
    expect(state.data!.representativeEmail, 'maria@empresa.com.br');
    expect(state.data!.representativePhone, '11987654321');
    expect(state.data!.representativeCpf, '52998224725');
    expect(state.data!.documentType, 'RG');
    verify(() => client.from('v_user_agency_onboarding_context')).called(1);
  });

  test('erro na query define estado error com load error message', () async {
    when(() => auth.currentUser).thenAnswer((_) => _user('user-1'));
    final queryBuilder = _FakeStatusQueryBuilder(
      _FakeStatusFilterBuilder(error: Exception('network')),
    );
    when(() => client.from('v_user_agency_onboarding_context'))
        .thenAnswer((_) => queryBuilder);

    final container = _makeContainer(client: client);
    addTearDown(container.dispose);

    await _readNotifier(container).load();

    final state = _readState(container);
    expect(state.status, AgencyStatusLoading.error);
    expect(
      state.error,
      'Não foi possível carregar o status da agência.',
    );
  });

  test('copyWith preserva todos os campos incluindo os 4 novos', () {
    final data = AgencyStatusData.fromJson(_statusJson());

    final copy = data.copyWith(
      agencyLegalName: 'Outra Agencia',
      representativeName: 'Outro Representante',
    );

    expect(copy.agencyLegalName, 'Outra Agencia');
    expect(copy.representativeName, 'Outro Representante');
    expect(copy.representativeEmail, data.representativeEmail);
    expect(copy.representativePhone, data.representativePhone);
    expect(copy.representativeCpf, data.representativeCpf);
    expect(copy.documentFrontUrl, data.documentFrontUrl);
    expect(copy.documentBackUrl, data.documentBackUrl);
    expect(copy.documentType, data.documentType);
    expect(copy.consolidatedDocumentStatus, data.consolidatedDocumentStatus);
  });

  test('status approved define consolidatedDocumentStatus correto', () {
    final data = AgencyStatusData.fromJson(
      _statusJson(
        statusAgency: 'approved',
        consolidatedDocumentStatus: 'approved',
      ),
    );

    expect(data.statusAgency, AgencyDocumentStatus.approved);
    expect(data.consolidatedDocumentStatus, AgencyDocumentStatus.approved);
  });

  test('status rejected define consolidatedDocumentStatus correto', () {
    final data = AgencyStatusData.fromJson(
      _statusJson(
        statusAgency: 'rejected',
        consolidatedDocumentStatus: 'rejected',
      ),
    );

    expect(data.statusAgency, AgencyDocumentStatus.rejected);
    expect(data.consolidatedDocumentStatus, AgencyDocumentStatus.rejected);
    expect(data.rejectionReason, 'Documento ilegivel');
  });
}
