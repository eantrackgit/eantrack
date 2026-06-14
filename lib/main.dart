import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_version.dart';
import 'features/auth/data/auth_callback_detector.dart';
import 'shared/shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.load();

  if (!AppConfig.isConfigured) {
    runApp(const _MissingConfigApp());
    return;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  await _applyKeepConnectedPreferenceToRestoredSession();
  setInitialThemeMode(await _loadInitialThemeMode());

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = AppConfig.sentryDsn.isEmpty ? 'development' : 'production';
    },
    appRunner: () => runApp(
      const ProviderScope(child: EanTrackApp()),
    ),
  );
}

Future<void> _applyKeepConnectedPreferenceToRestoredSession() async {
  if (hasAuthCallbackParams(Uri.base)) return;

  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    // Single indexed read at startup (no write). If it fails, the restored
    // session is kept as-is — a transient error must not sign the user out.
    // This is an intentional fail-open: a user with keep_connected = false
    // who hits a transient read error stays logged in for this boot instead
    // of being signed out by a network blip; the preference is re-checked
    // on the next boot/login.
    final keepConnected =
        await UserSettingsRepository().getKeepConnected(user.id);

    // Hand the value off to KeepConnectedController.load() so app.dart's
    // startup load for the same userId reuses it instead of repeating the
    // SELECT.
    KeepConnectedBootCache.set(user.id, keepConnected);

    if (keepConnected) return;

    // Supabase Auth remains the source of session tokens. This preference only
    // tells the app to discard an automatically restored local session.
    await const KeepConnectedPromptStorage().clearSavedLoginEmail();
    await supabase.auth.signOut(scope: SignOutScope.local);
  } on Exception catch (e) {
    debugPrint('[UserSettings] Erro ao aplicar preferencia lembrar-me: $e');
  }
}

Future<ThemeMode> _loadInitialThemeMode() async {
  final localStorage = const LocalThemeStorage();
  final localTheme = await _loadLocalThemeMode(localStorage);
  var initialTheme = localTheme ?? appDefaultThemeMode;

  if (Supabase.instance.client.auth.currentUser == null) {
    return initialTheme;
  }

  try {
    final settings = await UserSettingsRepository().loadSettings();
    final remoteTheme = themeModeFromSettings(settings);
    if (remoteTheme != null) {
      initialTheme = remoteTheme;
      try {
        await localStorage.saveThemeMode(remoteTheme);
      } on Exception catch (e) {
        debugPrint('[UserSettings] Erro ao sincronizar tema local: $e');
      }
    }
    return initialTheme;
  } on Exception catch (e) {
    debugPrint('[UserSettings] Erro ao carregar tema inicial: $e');
    return initialTheme;
  }
}

Future<ThemeMode?> _loadLocalThemeMode(LocalThemeStorage localStorage) async {
  try {
    return await localStorage.loadThemeMode();
  } on Exception catch (e) {
    debugPrint('[UserSettings] Erro ao carregar tema local: $e');
    return null;
  }
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    final missingKeys = AppConfig.missingRequiredKeys;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Configuracao obrigatoria ausente: ${missingKeys.join(', ')}.\n\n'
              'Execute com:\n\n'
              'flutter run \\\n'
              '  --dart-define=SUPABASE_URL=https://<id>.supabase.co \\\n'
              '  --dart-define=SUPABASE_ANON_KEY=eyJ...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
