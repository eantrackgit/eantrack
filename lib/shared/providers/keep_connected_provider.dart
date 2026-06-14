import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/keep_connected_prompt_storage.dart';
import '../data/user_settings_repository.dart';
import 'theme_provider.dart';

final keepConnectedPromptStorageProvider =
    Provider<KeepConnectedPromptStorage>(
  (_) => const KeepConnectedPromptStorage(),
);

final keepConnectedControllerProvider =
    StateNotifierProvider<KeepConnectedController, KeepConnectedState>((ref) {
  return KeepConnectedController(
    ref.read(userSettingsRepositoryProvider),
    ref.read(keepConnectedPromptStorageProvider),
  );
});

/// Single-use handoff for the keep_connected value already read once in
/// main.dart (before runApp). KeepConnectedController.load() consumes it on
/// its first call for the same userId, avoiding a second SELECT for the same
/// boot session.
class KeepConnectedBootCache {
  KeepConnectedBootCache._();

  static String? _userId;
  static bool? _keepConnected;

  static void set(String userId, bool keepConnected) {
    _userId = userId;
    _keepConnected = keepConnected;
  }

  /// Returns the cached value for [userId] and clears it (single use).
  /// Returns null if nothing was cached for this userId.
  static bool? consume(String userId) {
    if (_userId != userId) return null;
    final value = _keepConnected;
    _userId = null;
    _keepConnected = null;
    return value;
  }
}

const _keepConnectedUnset = Object();

class KeepConnectedState {
  const KeepConnectedState({
    this.keepConnected = false,
    this.savedLoginEmail,
    this.savedDisplayName,
    this.isLoading = false,
    this.isLoadingSavedLoginEmail = false,
    this.isSaving = false,
    this.error,
  });

  final bool keepConnected;
  final String? savedLoginEmail;

  // savedDisplayName exists only to improve the saved-account card UX (the
  // identity avatar initials). It is never persisted in user_settings and is
  // never used for authentication.
  final String? savedDisplayName;
  final bool isLoading;
  final bool isLoadingSavedLoginEmail;
  final bool isSaving;
  final String? error;

  bool get hasSavedLoginEmail =>
      savedLoginEmail != null && savedLoginEmail!.trim().isNotEmpty;

  KeepConnectedState copyWith({
    bool? keepConnected,
    Object? savedLoginEmail = _keepConnectedUnset,
    Object? savedDisplayName = _keepConnectedUnset,
    bool? isLoading,
    bool? isLoadingSavedLoginEmail,
    bool? isSaving,
    Object? error = _keepConnectedUnset,
  }) {
    return KeepConnectedState(
      keepConnected: keepConnected ?? this.keepConnected,
      savedLoginEmail: identical(savedLoginEmail, _keepConnectedUnset)
          ? this.savedLoginEmail
          : savedLoginEmail as String?,
      savedDisplayName: identical(savedDisplayName, _keepConnectedUnset)
          ? this.savedDisplayName
          : savedDisplayName as String?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingSavedLoginEmail:
          isLoadingSavedLoginEmail ?? this.isLoadingSavedLoginEmail,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _keepConnectedUnset)
          ? this.error
          : error as String?,
    );
  }
}

class KeepConnectedController extends StateNotifier<KeepConnectedState> {
  KeepConnectedController(this._repository, this._promptStorage)
      : super(const KeepConnectedState());

  final UserSettingsRepository _repository;
  final KeepConnectedPromptStorage _promptStorage;

  // Tracks the userId already confirmed via getKeepConnected during this
  // session, so the boot/login sequence (main.dart + app.dart +
  // syncAfterLogin all call load() for the same user) issues a single
  // SELECT. Reset by clearSessionState() when the user changes.
  String? _loadedUserId;

  /// Single read of keep_connected from Supabase (no writes). Does not
  /// touch the local saved-email cache by itself — callers decide what to
  /// do with the value (see [syncAfterLogin]), so an automatic call here
  /// (token refresh, app restart) never silently clears the local cache.
  ///
  /// Subsequent calls for the same userId during this session are no-ops
  /// (the cached value in [state] is reused) unless [forceRefresh] is set —
  /// used by Preferencias to always reflect the database on open.
  Future<void> load({String? userId, bool forceRefresh = false}) async {
    final resolvedUserId = _resolveUserId(userId);
    if (resolvedUserId == null) {
      _loadedUserId = null;
      state = const KeepConnectedState();
      return;
    }

    if (!forceRefresh &&
        _loadedUserId == resolvedUserId &&
        state.error == null) {
      return;
    }

    final cached = KeepConnectedBootCache.consume(resolvedUserId);
    if (cached != null) {
      _loadedUserId = resolvedUserId;
      state = state.copyWith(keepConnected: cached, isLoading: false, error: null);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final keepConnected =
          await _repository.getKeepConnected(resolvedUserId);
      _loadedUserId = resolvedUserId;
      state = state.copyWith(
        keepConnected: keepConnected,
        isLoading: false,
      );
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao carregar preferencia lembrar-me: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Nao foi possivel carregar a preferencia.',
      );
    }
  }

  /// Runs once right after a successful login: confirms keep_connected from
  /// Supabase (single read) and syncs the local saved-account cache
  /// accordingly.
  /// true  -> refresh the cached email and display name for this login.
  /// false -> clear any locally cached email and display name.
  Future<void> syncAfterLogin(String userId, String? loginEmail) async {
    await load(userId: userId);
    if (state.error != null) return;

    if (state.keepConnected) {
      await saveSavedLoginEmail(loginEmail);
      await saveSavedDisplayName(
        resolveDisplayNameFromUser(Supabase.instance.client.auth.currentUser),
      );
    } else {
      await clearSavedLoginEmail();
    }
  }

  // Loads the full saved-account cache (email + display name) for the
  // saved-account card — local storage only, no Supabase read.
  Future<void> loadSavedLoginEmail() async {
    state = state.copyWith(isLoadingSavedLoginEmail: true);
    try {
      final email = await _promptStorage.loadSavedLoginEmail();
      final displayName = await _promptStorage.loadSavedDisplayName();
      state = state.copyWith(
        savedLoginEmail: email,
        savedDisplayName: displayName,
        isLoadingSavedLoginEmail: false,
      );
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao carregar e-mail local: $e');
      state = state.copyWith(
        savedLoginEmail: null,
        savedDisplayName: null,
        isLoadingSavedLoginEmail: false,
      );
    }
  }

  Future<void> saveSavedLoginEmail(String? email) async {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      await clearSavedLoginEmail();
      return;
    }

    try {
      await _promptStorage.saveSavedLoginEmail(normalizedEmail);
      state = state.copyWith(savedLoginEmail: normalizedEmail);
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao salvar e-mail local: $e');
    }
  }

  // savedDisplayName exists only to improve the saved-account card UX (the
  // identity avatar initials). It is never persisted in user_settings and is
  // never used for authentication.
  Future<void> saveSavedDisplayName(String? name) async {
    final normalizedName = name?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      try {
        await _promptStorage.clearSavedDisplayName();
      } on Exception catch (e) {
        debugPrint('[UserSettings] Erro ao limpar nome local: $e');
      } finally {
        state = state.copyWith(savedDisplayName: null);
      }
      return;
    }

    try {
      await _promptStorage.saveSavedDisplayName(normalizedName);
      state = state.copyWith(savedDisplayName: normalizedName);
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao salvar nome local: $e');
    }
  }

  Future<void> clearSavedLoginEmail() async {
    try {
      await _promptStorage.clearSavedLoginEmail();
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao limpar e-mail local: $e');
    } finally {
      state = state.copyWith(savedLoginEmail: null, savedDisplayName: null);
    }
  }

  Future<bool> setKeepConnected(
    bool value, {
    String? userId,
    String? savedLoginEmail,
    String? savedDisplayName,
  }) async {
    final resolvedUserId = _resolveUserId(userId);
    if (resolvedUserId == null) {
      state = state.copyWith(error: 'Usuario nao autenticado.');
      return false;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    final resolvedEmail = savedLoginEmail ?? currentUser?.email;
    final resolvedDisplayName =
        savedDisplayName ?? resolveDisplayNameFromUser(currentUser);

    // Already in sync with the requested value: skip the database round
    // trip entirely (no read, no write) and only sync the local cache.
    if (state.keepConnected == value && !state.isLoading) {
      if (value) {
        await saveSavedLoginEmail(resolvedEmail);
        await saveSavedDisplayName(resolvedDisplayName);
      } else {
        await clearSavedLoginEmail();
      }
      return true;
    }

    final previousValue = state.keepConnected;
    state = state.copyWith(
      keepConnected: value,
      isSaving: true,
      error: null,
    );

    try {
      final savedValue = await _repository.setKeepConnectedIfChanged(
        resolvedUserId,
        value,
      );
      // The write above confirms keep_connected for this userId, so a
      // later load() for the same user can reuse it without a new SELECT.
      _loadedUserId = resolvedUserId;
      state = state.copyWith(
        keepConnected: savedValue,
        isSaving: false,
      );
      if (savedValue) {
        await saveSavedLoginEmail(resolvedEmail);
        await saveSavedDisplayName(resolvedDisplayName);
      } else {
        await clearSavedLoginEmail();
      }
      return true;
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao salvar preferencia lembrar-me: $e');
      state = state.copyWith(
        keepConnected: previousValue,
        isSaving: false,
        error: 'Nao foi possivel salvar a preferencia.',
      );
      return false;
    }
  }

  /// The prompt is controlled purely by a local per-userId flag, so it is
  /// shown once and never reappears on F5/restart for that user/device —
  /// no database read is needed just to decide this.
  Future<bool> shouldShowPrompt(String userId) async {
    final wasAnswered = await _promptStorage.wasPromptAnswered(userId);
    return !wasAnswered;
  }

  Future<bool> answerPrompt(
    String userId,
    bool keepConnected, {
    String? loginEmail,
  }) async {
    final saved = await setKeepConnected(
      keepConnected,
      userId: userId,
      savedLoginEmail: keepConnected ? loginEmail : null,
    );
    if (!saved) return false;

    await _promptStorage.markPromptAnswered(userId);
    return true;
  }

  void clearSessionState() {
    _loadedUserId = null;
    state = KeepConnectedState(
      savedLoginEmail: state.savedLoginEmail,
      savedDisplayName: state.savedDisplayName,
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  String? _resolveUserId(String? userId) {
    final explicitUserId = userId?.trim();
    if (explicitUserId != null && explicitUserId.isNotEmpty) {
      return explicitUserId;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id.trim();
    return currentUserId == null || currentUserId.isEmpty
        ? null
        : currentUserId;
  }
}

// Same metadata-key priority used across the app (hub, regions, agency
// status screens) to resolve a human-friendly display name for the
// authenticated user. Used to seed savedDisplayName (here and from
// AuthNotifier.signOut, which preserves it on logout for keep_connected = true).
String? resolveDisplayNameFromUser(User? user) {
  final metadata = user?.userMetadata;
  if (metadata == null) return null;

  for (final key in const ['nome', 'name', 'full_name', 'display_name']) {
    final value = metadata[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }

  return null;
}
