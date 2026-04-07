import 'package:eantrack/core/error/app_exception.dart';
import 'package:eantrack/features/regions/data/region_repository.dart';
import 'package:eantrack/features/regions/domain/region_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Fake builder that resolves to [_value] when awaited.
///
/// Used to satisfy the `PostgrestFilterBuilder<dynamic>` return type of
/// `SupabaseClient.rpc()` while still providing meaningful test data.
class _FakePostgrestBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakePostgrestBuilder(this._value);
  final dynamic _value;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic) onValue, {
    Function? onError,
  }) =>
      Future<dynamic>.value(_value).then(onValue, onError: onError);

  @override
  Future<dynamic> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) =>
      Future<dynamic>.value(_value);

  @override
  Future<dynamic> whenComplete(FutureOr<void> Function() action) =>
      Future<dynamic>.value(_value).whenComplete(action);

  @override
  Stream<dynamic> asStream() => Stream.value(_value);

  @override
  Future<dynamic> timeout(
    Duration timeLimit, {
    FutureOr<dynamic> Function()? onTimeout,
  }) =>
      Future<dynamic>.value(_value).timeout(timeLimit, onTimeout: onTimeout);

  // Allow builder chaining (.select(), .eq(), etc.) without breaking the chain.
  _FakePostgrestBuilder select([String columns = '*']) => this;
}

void main() {
  late MockSupabaseClient client;
  late RegionRepository repository;

  const agencyId = 'agency-uuid-001';

  setUp(() {
    client = MockSupabaseClient();
    repository = RegionRepository(client);
  });

  group('RegionModel.fromRpc', () {
    test('parseia campos corretamente', () {
      final model = RegionModel.fromRpc({
        'id': 'region-1',
        'name': 'Sul de Minas',
        'city_count': 12,
        'is_active': true,
      });

      expect(model.id, 'region-1');
      expect(model.name, 'Sul de Minas');
      expect(model.cityCount, 12);
      expect(model.isActive, true);
    });

    test('usa defaults para campos ausentes', () {
      final model = RegionModel.fromRpc({
        'id': 'region-2',
        'name': 'Norte',
      });

      expect(model.cityCount, 0);
      expect(model.isActive, true);
    });

    test('parseia city_count como num corretamente', () {
      final model = RegionModel.fromRpc({
        'id': 'r',
        'name': 'Teste',
        'city_count': 5.0, // pode vir como double do Postgres
        'is_active': false,
      });

      expect(model.cityCount, 5);
      expect(model.isActive, false);
    });
  });

  group('fetchRegions', () {
    test('retorna lista de regiões ao receber dados da RPC', () async {
      when(
        () => client.rpc(
          'list_regions_by_agency_exhibition',
          params: any(named: 'params'),
        ),
      ).thenReturn(_FakePostgrestBuilder([
        {'id': 'r1', 'name': 'Norte', 'city_count': 3, 'is_active': true},
        {'id': 'r2', 'name': 'Sul', 'city_count': 7, 'is_active': false},
      ]));

      final result = await repository.fetchRegions(agencyId: agencyId);

      expect(result, hasLength(2));
      expect(result.first.name, 'Norte');
      expect(result.last.isActive, false);
    });

    test('retorna lista vazia quando RPC retorna []', () async {
      when(
        () => client.rpc(
          'list_regions_by_agency_exhibition',
          params: any(named: 'params'),
        ),
      ).thenReturn(_FakePostgrestBuilder(<dynamic>[]));

      final result = await repository.fetchRegions(agencyId: agencyId);

      expect(result, isEmpty);
    });

    test('lança ServerException em erro PostgrestException', () async {
      when(
        () => client.rpc(
          'list_regions_by_agency_exhibition',
          params: any(named: 'params'),
        ),
      ).thenThrow(
        PostgrestException(message: 'permission denied', code: '42501'),
      );

      expect(
        () => repository.fetchRegions(agencyId: agencyId),
        throwsA(isA<ServerException>()),
      );
    });

    test('lança ServerException em erro genérico', () async {
      when(
        () => client.rpc(
          'list_regions_by_agency_exhibition',
          params: any(named: 'params'),
        ),
      ).thenThrow(Exception('network'));

      expect(
        () => repository.fetchRegions(agencyId: agencyId),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('isNameAvailable', () {
    test('retorna true quando RPC retorna bool true', () async {
      when(
        () => client.rpc(
          'is_region_name_available_for_current_user',
          params: any(named: 'params'),
        ),
      ).thenReturn(_FakePostgrestBuilder(true));

      final result = await repository.isNameAvailable('Norte');

      expect(result, isTrue);
    });

    test('retorna false quando RPC retorna bool false', () async {
      when(
        () => client.rpc(
          'is_region_name_available_for_current_user',
          params: any(named: 'params'),
        ),
      ).thenReturn(_FakePostgrestBuilder(false));

      final result = await repository.isNameAvailable('Norte');

      expect(result, isFalse);
    });

    test('retorna true quando RPC retorna Map com available: true', () async {
      when(
        () => client.rpc(
          'is_region_name_available_for_current_user',
          params: any(named: 'params'),
        ),
      ).thenReturn(_FakePostgrestBuilder({'available': true}));

      final result = await repository.isNameAvailable('Norte');

      expect(result, isTrue);
    });

    test('retorna true em caso de falha da RPC (fail-open)', () async {
      when(
        () => client.rpc(
          'is_region_name_available_for_current_user',
          params: any(named: 'params'),
        ),
      ).thenThrow(Exception('timeout'));

      final result = await repository.isNameAvailable('Norte');

      expect(result, isTrue); // fail-open → banco rejeitará duplicata
    });
  });
}
