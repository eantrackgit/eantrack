import 'package:eantrack/features/onboarding/agency/controllers/agency_cnpj_controller.dart';
import 'package:eantrack/features/onboarding/agency/models/cnpj_model.dart';
import 'package:eantrack/features/onboarding/agency/services/cnpj_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCnpjService extends Mock implements CnpjService {}

const _validCnpj = '11222333000181';

const _cnpjModel = CnpjModel(
  cnpj: _validCnpj,
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

ProviderContainer _makeContainer(MockCnpjService service) {
  return ProviderContainer(
    overrides: [
      agencyCnpjProvider.overrideWith((ref) {
        final controller = TextEditingController();
        final focusNode = FocusNode();

        ref.onDispose(controller.dispose);
        ref.onDispose(focusNode.dispose);

        return AgencyCnpjNotifier(
          controller,
          focusNode,
          service: service,
        );
      }),
    ],
  );
}

void main() {
  late MockCnpjService service;

  setUp(() {
    service = MockCnpjService();
  });

  test('estado inicial e idle', () {
    final container = _makeContainer(service);
    addTearDown(container.dispose);

    final state = container.read(agencyCnpjProvider);

    expect(state.status, AgencyCnpjStatus.idle);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.cnpjData, isNull);
  });

  test('CNPJ valido encontrado define estado success com CnpjModel', () async {
    when(() => service.fetchCnpj(_validCnpj)).thenAnswer((_) async => _cnpjModel);
    when(() => service.cnpjExistsAgency(_validCnpj)).thenAnswer((_) async => false);

    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = container.read(agencyCnpjProvider.notifier);

    notifier.textController.text = _validCnpj;
    await notifier.consultCnpj();

    final state = container.read(agencyCnpjProvider);
    expect(state.status, AgencyCnpjStatus.success);
    expect(state.cnpjData, _cnpjModel);
    expect(state.canAdvance, isTrue);
    verify(() => service.fetchCnpj(_validCnpj)).called(1);
    verify(() => service.cnpjExistsAgency(_validCnpj)).called(1);
  });

  test('CNPJ nao encontrado define estado notFound', () async {
    when(() => service.fetchCnpj(_validCnpj))
        .thenThrow(const CnpjNotFoundException());

    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = container.read(agencyCnpjProvider.notifier);

    notifier.textController.text = _validCnpj;
    await notifier.consultCnpj();

    final state = container.read(agencyCnpjProvider);
    expect(state.status, AgencyCnpjStatus.notFound);
    expect(state.cnpjData, isNull);
    expect(state.error, isNotNull);
    verifyNever(() => service.cnpjExistsAgency(any()));
  });

  test('erro de rede define estado error com mensagem tipada', () async {
    when(() => service.fetchCnpj(_validCnpj))
        .thenThrow(const CnpjServiceException('Falha de rede.'));

    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = container.read(agencyCnpjProvider.notifier);

    notifier.textController.text = _validCnpj;
    await notifier.consultCnpj();

    final state = container.read(agencyCnpjProvider);
    expect(state.status, AgencyCnpjStatus.genericError);
    expect(state.error, 'Erro ao consultar CNPJ. Tente novamente.');
    expect(state.cnpjData, isNull);
    verifyNever(() => service.cnpjExistsAgency(any()));
  });

  test('CNPJ invalido por formato define estado invalidFormat', () async {
    final container = _makeContainer(service);
    addTearDown(container.dispose);
    final notifier = container.read(agencyCnpjProvider.notifier);

    notifier.textController.text = '123';
    await notifier.consultCnpj();

    final state = container.read(agencyCnpjProvider);
    expect(state.status, AgencyCnpjStatus.invalid);
    expect(state.isLoading, isFalse);
    expect(state.error, isNotNull);
    verifyNever(() => service.fetchCnpj(any()));
    verifyNever(() => service.cnpjExistsAgency(any()));
  });
}
