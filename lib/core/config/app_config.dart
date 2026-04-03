/// App configuration via dart-define.
///
/// Build command:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://<project>.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// Ambas as variáveis são obrigatórias.
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

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

