import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:http/http.dart' as http;

abstract class ConnectivityService {
  Future<bool> hasInternet();
  Stream<void> get onConnectivityChanged;
}

class HttpConnectivityService implements ConnectivityService {
  static final _kDefaultEndpoints = [
    Uri.parse('https://clients3.google.com/generate_204'),
    Uri.parse('https://www.cloudflare.com/cdn-cgi/trace'),
  ];

  static InternetConnection _buildConnection(
    List<Uri> endpoints,
    Duration timeout,
  ) =>
      InternetConnection.createInstance(
        useDefaultOptions: false,
        customCheckOptions: endpoints
            .map((uri) => InternetCheckOption(uri: uri, timeout: timeout))
            .toList(growable: false),
      );

  HttpConnectivityService({
    List<Uri>? endpoints,
    Duration? timeout,
    InternetConnection? connection,
  })  : _endpoints = endpoints ?? _kDefaultEndpoints,
        _timeout = timeout ?? const Duration(seconds: 3),
        _connection = connection ??
            _buildConnection(
              endpoints ?? _kDefaultEndpoints,
              timeout ?? const Duration(seconds: 3),
            );

  final List<Uri> _endpoints;
  final Duration _timeout;
  final InternetConnection _connection;

  @override
  Stream<void> get onConnectivityChanged {
    return _connection.onStatusChange.map((_) {});
  }

  @override
  Future<bool> hasInternet() async {
    final client = http.Client();
    try {
      final results = await Future.wait(
        _endpoints.map((endpoint) async {
          try {
            final response = await client.get(endpoint).timeout(_timeout);
            return response.statusCode >= 200 && response.statusCode < 400;
          } catch (_) {
            return false;
          }
        }),
      );
      return results.any((r) => r);
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
