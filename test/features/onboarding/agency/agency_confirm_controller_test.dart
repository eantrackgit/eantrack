import 'package:eantrack/features/onboarding/agency/controllers/agency_confirm_controller.dart';
import 'package:eantrack/features/onboarding/agency/models/cnpj_model.dart';
import 'package:eantrack/features/onboarding/agency/services/agency_confirm_service.dart';
import 'package:eantrack/features/onboarding/agency/services/cep_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCepService extends Mock implements CepService {}

class MockAgencyConfirmService extends Mock implements AgencyConfirmService {}

class FakeCnpjModel extends Fake implements CnpjModel {}

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

const _cepAddress = CepAddress(
  cep: '01311000',
  logradouro: 'Avenida Paulista',
  bairro: 'Bela Vista',
  municipio: 'Sao Paulo',
  uf: 'SP',
);

ProviderContainer _makeContainer({
  required MockCepService cepService,
  required MockAgencyConfirmService confirmService,
}) {
  final container = ProviderContainer(
    overrides: [
      agencyConfirmProvider(_cnpjModel).overrideWith((ref) {
        return AgencyConfirmNotifier(
          cnpjModel: _cnpjModel,
          cepService: cepService,
          confirmService: confirmService,
        );
      }),
    ],
  );
  container.listen(agencyConfirmProvider(_cnpjModel), (_, __) {});
  return container;
}

AgencyConfirmNotifier _readNotifier(ProviderContainer container) {
  return container.read(agencyConfirmProvider(_cnpjModel).notifier);
}

void _fillValidContact(AgencyConfirmNotifier notifier) {
  notifier.phoneController.text = '11987654321';
  notifier.emailController.text = 'contato@empresa.com';
}

void main() {
  late MockCepService cepService;
  late MockAgencyConfirmService confirmService;

  setUpAll(() {
    registerFallbackValue(FakeCnpjModel());
  });

  setUp(() {
    cepService = MockCepService();
    confirmService = MockAgencyConfirmService();
  });

  test('estado inicial carrega dados do CnpjModel', () {
    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    expect(notifier.fantasyNameController.text, _cnpjModel.displayName);
    expect(notifier.cepController.text, CnpjModel.formatCep(_cnpjModel.cep));
    expect(notifier.logradouroController.text, _cnpjModel.logradouro);
    expect(notifier.numeroController.text, _cnpjModel.numero);
    expect(notifier.bairroController.text, _cnpjModel.bairro);
    expect(notifier.municipioController.text, _cnpjModel.municipio);
    expect(notifier.ufController.text, _cnpjModel.uf);
    expect(container.read(agencyConfirmProvider(_cnpjModel)).canAdvance, isFalse);
  });

  test('telefone invalido exibe erro de validacao', () async {
    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    notifier.phoneController.text = '1198765';
    notifier.emailController.text = 'contato@empresa.com.br';

    final ok = await notifier.submit();
    final state = container.read(agencyConfirmProvider(_cnpjModel));

    expect(ok, isFalse);
    expect(state.phoneError, 'Informe um telefone válido.');
    verifyNever(
      () => confirmService.saveAgency(
        cnpjModel: any(named: 'cnpjModel'),
        nomeFantasia: any(named: 'nomeFantasia'),
        telefoneContato: any(named: 'telefoneContato'),
        email: any(named: 'email'),
        cep: any(named: 'cep'),
        logradouro: any(named: 'logradouro'),
        numero: any(named: 'numero'),
        bairro: any(named: 'bairro'),
        municipio: any(named: 'municipio'),
        uf: any(named: 'uf'),
      ),
    );
  });

  test('e-mail invalido exibe erro de validacao', () async {
    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    notifier.phoneController.text = '11987654321';
    notifier.emailController.text = 'email-invalido';

    final ok = await notifier.submit();
    final state = container.read(agencyConfirmProvider(_cnpjModel));

    expect(ok, isFalse);
    expect(state.emailError, 'Informe um e-mail válido.');
    verifyNever(
      () => confirmService.saveAgency(
        cnpjModel: any(named: 'cnpjModel'),
        nomeFantasia: any(named: 'nomeFantasia'),
        telefoneContato: any(named: 'telefoneContato'),
        email: any(named: 'email'),
        cep: any(named: 'cep'),
        logradouro: any(named: 'logradouro'),
        numero: any(named: 'numero'),
        bairro: any(named: 'bairro'),
        municipio: any(named: 'municipio'),
        uf: any(named: 'uf'),
      ),
    );
  });

  test('CEP valido preenche endereco via CepService', () async {
    when(() => cepService.fetchCep('01311000'))
        .thenAnswer((_) async => _cepAddress);

    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    notifier.cepController.text = '01311-000';
    await notifier.searchCep();

    final state = container.read(agencyConfirmProvider(_cnpjModel));
    expect(state.cepMessage, isNull);
    expect(state.isSearchingCep, isFalse);
    expect(notifier.cepController.text, '01311-000');
    expect(notifier.logradouroController.text, 'AVENIDA PAULISTA');
    expect(notifier.bairroController.text, 'BELA VISTA');
    expect(notifier.municipioController.text, 'SAO PAULO');
    expect(notifier.ufController.text, 'SP');
    verify(() => cepService.fetchCep('01311000')).called(1);
  });

  test('CEP nao encontrado define estado error', () async {
    when(() => cepService.fetchCep('01311000'))
        .thenThrow(const CepNotFoundException());

    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);

    notifier.cepController.text = '01311-000';
    await notifier.searchCep();

    final state = container.read(agencyConfirmProvider(_cnpjModel));
    expect(state.cepMessage, 'CEP não encontrado.');
    expect(state.isSearchingCep, isFalse);
    expect(notifier.logradouroController.text, isEmpty);
    expect(notifier.bairroController.text, isEmpty);
    expect(notifier.municipioController.text, isEmpty);
    expect(notifier.ufController.text, isEmpty);
  });

  test('submit com agencia ja existente define erro tipado', () async {
    when(
      () => confirmService.saveAgency(
        cnpjModel: any(named: 'cnpjModel'),
        nomeFantasia: any(named: 'nomeFantasia'),
        telefoneContato: any(named: 'telefoneContato'),
        email: any(named: 'email'),
        cep: any(named: 'cep'),
        logradouro: any(named: 'logradouro'),
        numero: any(named: 'numero'),
        bairro: any(named: 'bairro'),
        municipio: any(named: 'municipio'),
        uf: any(named: 'uf'),
      ),
    ).thenThrow(const AgencyAlreadyRegisteredException());

    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);
    _fillValidContact(notifier);

    final ok = await notifier.submit();
    final state = container.read(agencyConfirmProvider(_cnpjModel));

    expect(ok, isFalse);
    expect(state.isConfirmed, isFalse);
    expect(state.savedAgencyId, isNull);
    expect(state.submitErrorMessage, 'Esta agência já está cadastrada.');
  });

  test('submit bem-sucedido prepara payload para a proxima rota', () async {
    when(
      () => confirmService.saveAgency(
        cnpjModel: any(named: 'cnpjModel'),
        nomeFantasia: any(named: 'nomeFantasia'),
        telefoneContato: any(named: 'telefoneContato'),
        email: any(named: 'email'),
        cep: any(named: 'cep'),
        logradouro: any(named: 'logradouro'),
        numero: any(named: 'numero'),
        bairro: any(named: 'bairro'),
        municipio: any(named: 'municipio'),
        uf: any(named: 'uf'),
      ),
    ).thenAnswer((_) async => 'fake-agency-id');

    final container = _makeContainer(
      cepService: cepService,
      confirmService: confirmService,
    );
    addTearDown(container.dispose);
    final notifier = _readNotifier(container);
    _fillValidContact(notifier);

    final ok = await notifier.submit();
    final state = container.read(agencyConfirmProvider(_cnpjModel));
    final payload = notifier.buildPayload();

    expect(ok, isTrue);
    expect(state.isConfirmed, isTrue);
    expect(state.savedAgencyId, 'fake-agency-id');
    expect(payload.agencyId, 'fake-agency-id');
    expect(payload.cnpjModel, _cnpjModel);
    verify(
      () => confirmService.saveAgency(
        cnpjModel: _cnpjModel,
        nomeFantasia: _cnpjModel.displayName,
        telefoneContato: '11987654321',
        email: 'contato@empresa.com',
        cep: CnpjModel.formatCep(_cnpjModel.cep),
        logradouro: _cnpjModel.logradouro,
        numero: _cnpjModel.numero!,
        bairro: _cnpjModel.bairro,
        municipio: _cnpjModel.municipio,
        uf: _cnpjModel.uf,
      ),
    ).called(1);
  });
}
