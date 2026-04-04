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
    defaultValue: 'http://localhost:8080',
  );

  static String get passwordResetRedirectUrl =>
      '$appOrigin/#/update-password';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

