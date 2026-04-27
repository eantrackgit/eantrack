import 'dart:typed_data';

import 'package:eantrack/features/onboarding/agency/controllers/agency_representative_controller.dart';
import 'package:eantrack/features/onboarding/agency/controllers/agency_status_notifier.dart';
import 'package:eantrack/features/onboarding/agency/models/agency_confirm_payload.dart';
import 'package:eantrack/features/onboarding/agency/models/agency_representative_model.dart';
import 'package:eantrack/features/onboarding/agency/models/cnpj_model.dart';
import 'package:eantrack/features/onboarding/agency/services/agency_representative_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAgencyRepresentativeService extends Mock
    implements AgencyRepresentativeService {}

class FakeAgencyRepresentativeSubmission extends Fake
    implements AgencyRepresentativeSubmission {}

const _cnpjModel = CnpjModel(
  cnpj: '11222333000181',
  razaoSocial: 'Empresa Teste LTDA',
  nomeFantasia: 'Empresa Teste',
  situacaoCadastral: 'ATIVA',
  porte: 'ME',
  cnaePrincipal: 'Comercio varejista',
  numero: '100',
  cep: '01001000',
  logradouro: 'Praca da Se',
  bairro: 'Se',
  municipio: 'Sao Paulo',
  uf: 'SP',
);

const _payload = AgencyConfirmPayload(
  agencyId: 'agency-1',
  cnpjModel: _cnpjModel,
  formData: AgencyConfirmFormData(
    nomeFantasia: 'Empresa Teste',
    telefoneContato: '11987654321',
    email: 'contato@empresa.com.br',
    cep: '01001000',
    logradouro: 'Praca da Se',
    numero: '100',
    bairro: 'Se',
    municipio: 'Sao Paulo',
    uf: 'SP',
  ),
);

final _frontFile = AgencyRepresentativePickedFile(
  fileName: 'frente.png',
  bytes: Uint8List.fromList([1, 2, 3]),
  sizeInBytes: 3,
  contentType: 'image/png',
);

final _backFile = AgencyRepresentativePickedFile(
  fileName: 'verso.png',
  bytes: Uint8List.fromList([4, 5, 6]),
  sizeInBytes: 3,
  contentType: 'image/png',
);

ProviderContainer _makeContainer(MockAgencyRepresentativeService service) {
  final container = ProviderContainer(
    overrides: [
      agencyRepresentativeProvider(_payload).overrideWith((ref) {
        return AgencyRepresentativeNotifier(
          payload: _payload,
          service: service,
        );
      }),
    ],
  );
  container.listen(agencyRepresentativeProvider(_payload), (_, __) {});
  return container;
}

AgencyRepresentativeNotifier _readNotifier(ProviderContainer container) {
  return container.read(agencyRepresentativeProvider(_payload).notifier);
}

AgencyRepresentativeState _readState(ProviderContainer container) {
  return container.read(agencyRepresentativeProvider(_payload));
}

void _fillValidForm(AgencyRepresentativeNotifier notifier) {
  notifier.fullNameController.text = 'Maria Silva';
  notifier.cpfController.text = '52998224725';
  notifier.phoneController.text = '11987654321';
  notifier.emailController.text = 'maria@empresa.com';
  notifier.onCpfBlur();
  notifier.updateRole('Diretor');
  notifier.selectDocumentType(AgencyRepresentativeDocumentType.rg);
  notifier.receiveDroppedFile(
    AgencyRepresentativeAttachmentSlot.front,
    _frontFile,
  );
  notifier.receiveDroppedFile(
    AgencyRepresentativeAttachmentSlot.back,
    _backFile,
  );
}

void main() {
  late MockAgencyRepresentativeService service;

  setUpAll(() {
    registerFallbackValue(FakeAgencyRepresentativeSubmission());
  });

  setUp(() {
    service = MockAgencyRepresentativeService();
  });

  test('estado inicial e idle', () {
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    final state = _readState(container);

    expect(state.submitted, isFalse);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.documents, isEmpty);
    expect(state.canAdvance, isFalse);
  });

  test('CPF invalido exibe erro de validacao', () async {
    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    _fillValidForm(notifier);
    notifier.cpfController.text = '11111111111';

    final ok = await notifier.submit();
    final state = _readState(container);

    expect(ok, isFalse);
    expect(state.cpfError, 'Informe um CPF válido.');
    verifyNever(() => service.submit(any()));
  });

  test('telefone invalido exibe erro de validacao', () async {
    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    _fillValidForm(notifier);
    notifier.phoneController.text = '1198765';

    final ok = await notifier.submit();
    final state = _readState(container);

    expect(ok, isFalse);
    expect(state.phoneError, 'Informe um telefone válido.');
    verifyNever(() => service.submit(any()));
  });

  test('e-mail invalido exibe erro de validacao', () async {
    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    _fillValidForm(notifier);
    notifier.emailController.text = 'email-invalido';

    final ok = await notifier.submit();
    final state = _readState(container);

    expect(ok, isFalse);
    expect(state.emailError, 'Informe um e-mail válido.');
    verifyNever(() => service.submit(any()));
  });

  test('upload de documento bem-sucedido retorna success', () async {
    when(() => service.submit(any())).thenAnswer((_) async {});

    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);
    _fillValidForm(notifier);

    final ok = await notifier.submit();
    final state = _readState(container);

    expect(ok, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.documents, [_frontFile, _backFile]);
    verify(
      () => service.submit(
        any(
          that: isA<AgencyRepresentativeSubmission>()
              .having((s) => s.agencyId, 'agencyId', 'agency-1')
              .having((s) => s.documentType, 'documentType',
                  AgencyRepresentativeDocumentType.rg)
              .having((s) => s.frontFile, 'frontFile', _frontFile)
              .having((s) => s.backFile, 'backFile', _backFile),
        ),
      ),
    ).called(1);
  });

  test('falha no upload faz rollback do loading e define error', () async {
    when(() => service.submit(any())).thenThrow(
      const AgencyRepresentativeServiceException(
        'Falha no upload do documento.',
      ),
    );

    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);
    _fillValidForm(notifier);

    final ok = await notifier.submit();
    final state = _readState(container);

    expect(ok, isFalse);
    expect(state.isLoading, isFalse);
    expect(state.error, 'Falha no upload do documento.');
    expect(state.documents, [_frontFile, _backFile]);
    verify(() => service.submit(any())).called(1);
  });

  test('prefill com AgencyStatusData preenche campos corretamente', () {
    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    notifier.prefill(
      AgencyStatusData(
        agencyId: 'agency-1',
        agencyLegalName: 'Empresa Teste LTDA',
        statusAgency: AgencyDocumentStatus.pending,
        agencyUpdatedAt: DateTime(2026, 4, 22),
        representativeName: 'Joao Legal',
        representativeEmail: 'joao@empresa.com.br',
        representativePhone: '11911112222',
        representativeCpf: '52998224725',
        documentType: 'CNH',
        consolidatedDocumentStatus: AgencyDocumentStatus.rejected,
      ),
    );

    final state = _readState(container);
    expect(notifier.fullNameController.text, 'Joao Legal');
    expect(notifier.emailController.text, 'joao@empresa.com.br');
    expect(notifier.phoneController.text, '(11) 9 1111-2222');
    expect(notifier.cpfController.text, '52998224725');
    expect(state.fullNameText, 'Joao Legal');
    expect(state.emailText, 'joao@empresa.com.br');
    expect(state.phoneText, '(11) 9 1111-2222');
    expect(state.cpfText, '52998224725');
    expect(state.selectedDocumentType, AgencyRepresentativeDocumentType.cnh);
    expect(state.error, isNull);
  });

  test('submit em modo correcao reaproveita representante existente', () async {
    when(() => service.submit(any())).thenAnswer((_) async {});
    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    notifier.prefill(
      AgencyStatusData(
        agencyId: 'agency-1',
        agencyLegalName: 'Empresa Teste LTDA',
        statusAgency: AgencyDocumentStatus.rejected,
        agencyUpdatedAt: DateTime(2026, 4, 22),
        representativeName: 'Joao Legal',
        representativeEmail: 'joao@empresa.com.br',
        legalRepresentativeId: 'rep-1',
        representativePhone: '11911112222',
        representativeCpf: '52998224725',
        documentType: 'RG',
        consolidatedDocumentStatus: AgencyDocumentStatus.rejected,
      ),
    );
    _fillValidForm(notifier);

    final ok = await notifier.submit();
    final captured = verify(() => service.submit(captureAny())).captured.single
        as AgencyRepresentativeSubmission;

    expect(ok, isTrue);
    expect(captured.legalRepresentativeId, 'rep-1');
  });
}
