import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/local_theme_storage.dart';
import '../data/user_settings_repository.dart';

const appDefaultThemeMode = ThemeMode.light;

ThemeMode _initialThemeMode = appDefaultThemeMode;

void setInitialThemeMode(ThemeMode mode) {
  _initialThemeMode = mode;
}

ThemeMode? themeModeFromSettings(Map<String, dynamic> settings) {
  final theme = settings['theme']?.toString().trim().toLowerCase();
  switch (theme) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return null;
  }
}

String themeModeToSettingsValue(ThemeMode mode) {
  return mode == ThemeMode.dark ? 'dark' : 'light';
}

final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => _initialThemeMode,
);

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>(
  (_) => UserSettingsRepository(),
);

final localThemeStorageProvider = Provider<LocalThemeStorage>(
  (_) => const LocalThemeStorage(),
);

final userThemeControllerProvider =
    StateNotifierProvider<UserThemeController, UserThemeState>((ref) {
  return UserThemeController(
    ref,
    ref.read(userSettingsRepositoryProvider),
    ref.read(localThemeStorageProvider),
  );
});

const _userThemeUnset = Object();

class UserThemeState {
  const UserThemeState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final bool isLoading;
  final bool isSaving;
  final String? error;

  UserThemeState copyWith({
    bool? isLoading,
    bool? isSaving,
    Object? error = _userThemeUnset,
  }) {
    return UserThemeState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _userThemeUnset) ? this.error : error as String?,
    );
  }
}

class UserThemeController extends StateNotifier<UserThemeState> {
  UserThemeController(this._ref, this._repository, this._localStorage)
      : super(const UserThemeState());

  final Ref _ref;
  final UserSettingsRepository _repository;
  final LocalThemeStorage _localStorage;
  bool _isApplyingStoredTheme = false;

  Future<void> loadForCurrentUser() async {
    if (Supabase.instance.client.auth.currentUser == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _repository.loadSettings();
      final mode = themeModeFromSettings(settings);
      if (mode != null) {
        await _localStorage.saveThemeMode(mode);
        _isApplyingStoredTheme = true;
        _ref.read(themeModeProvider.notifier).state = mode;
        Future.microtask(() => _isApplyingStoredTheme = false);
      }
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      _isApplyingStoredTheme = false;
      debugPrint('[UserSettings] Erro ao carregar tema: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> setTheme(ThemeMode mode) async {
    if (mode != ThemeMode.light && mode != ThemeMode.dark) return false;

    _ref.read(themeModeProvider.notifier).state = mode;
    return true;
  }

  Future<bool> persistThemeChange(ThemeMode mode) async {
    try {
      await _localStorage.saveThemeMode(mode);
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao salvar tema local: $e');
    }

    if (_isApplyingStoredTheme) return true;
    if (Supabase.instance.client.auth.currentUser == null) {
      return true;
    }

    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repository.upsertSettings({
        'theme': themeModeToSettingsValue(mode),
      });
      state = state.copyWith(isSaving: false);
      return true;
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao salvar tema: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'N\u00e3o foi poss\u00edvel salvar a configura\u00e7\u00e3o.',
      );
      return false;
    }
  }

  void clearSessionState() {
    state = const UserThemeState();
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}
