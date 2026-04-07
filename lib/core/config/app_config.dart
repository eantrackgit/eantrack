import 'package:flutter/foundation.dart' show kIsWeb;

/// App configuration via dart-define.
///
/// Build — desenvolvimento:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=APP_ORIGIN=http://localhost:PORT
///
/// Build — produção:
///   flutter build web \
///     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ... \
///     --dart-define=APP_ORIGIN=https://operational.eantrack.com
///
/// Todas as variáveis são obrigatórias em produção.
/// Nunca usar defaultValue com dados reais.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Base URL do ambiente (sem trailing slash).
  /// Dev:  http://localhost:PORT
  /// Prod: https://operational.eantrack.com
  static const appOrigin = String.fromEnvironment(
    'APP_ORIGIN',
    defaultValue: '',
  );

  static bool get isLocalhost {
    final host = Uri.base.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1';
  }

  static List<String> get missingRequiredKeys {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    return missing;
  }

  static String get _normalizedAppOrigin =>
      appOrigin.replaceFirst(RegExp(r'/$'), '');

  static String get effectiveAppOrigin {
    if (kIsWeb) {
      if (_normalizedAppOrigin.isNotEmpty) {
        return _normalizedAppOrigin;
      }
      return Uri.base.origin;
    }

    return _normalizedAppOrigin;
  }

  static String get passwordResetRedirectUrl {
    if (effectiveAppOrigin.isEmpty) {
      return '';
    }

    return '$effectiveAppOrigin/#/update-password';
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
