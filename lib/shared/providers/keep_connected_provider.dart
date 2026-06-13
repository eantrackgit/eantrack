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

const _keepConnectedUnset = Object();

class KeepConnectedState {
  const KeepConnectedState({
    this.keepConnected = false,
    this.savedLoginEmail,
    this.isLoading = false,
    this.isLoadingSavedLoginEmail = false,
    this.isSaving = false,
    this.error,
  });

  final bool keepConnected;
  final String? savedLoginEmail;
  final bool isLoading;
  final bool isLoadingSavedLoginEmail;
  final bool isSaving;
  final String? error;

  bool get hasSavedLoginEmail =>
      savedLoginEmail != null && savedLoginEmail!.trim().isNotEmpty;

  KeepConnectedState copyWith({
    bool? keepConnected,
    Object? savedLoginEmail = _keepConnectedUnset,
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

  Future<void> load({String? userId}) async {
    final resolvedUserId = _resolveUserId(userId);
    if (resolvedUserId == null) {
      state = const KeepConnectedState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final keepConnected =
          await _repository.getKeepConnected(resolvedUserId);
      state = state.copyWith(
        keepConnected: keepConnected,
        isLoading: false,
      );
      if (!keepConnected) {
        await clearSavedLoginEmail();
      }
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao carregar manter conectado: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Nao foi possivel carregar a preferencia.',
      );
    }
  }

  Future<void> loadSavedLoginEmail() async {
    state = state.copyWith(isLoadingSavedLoginEmail: true);
    try {
      final email = await _promptStorage.loadSavedLoginEmail();
      state = state.copyWith(
        savedLoginEmail: email,
        isLoadingSavedLoginEmail: false,
      );
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao carregar e-mail local: $e');
      state = state.copyWith(
        savedLoginEmail: null,
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

  Future<void> clearSavedLoginEmail() async {
    try {
      await _promptStorage.clearSavedLoginEmail();
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao limpar e-mail local: $e');
    } finally {
      state = state.copyWith(savedLoginEmail: null);
    }
  }

  Future<bool> setKeepConnected(
    bool value, {
    String? userId,
    String? savedLoginEmail,
  }) async {
    final resolvedUserId = _resolveUserId(userId);
    if (resolvedUserId == null) {
      state = state.copyWith(error: 'Usuario nao autenticado.');
      return false;
    }

    final previousValue = state.keepConnected;
    state = state.copyWith(
      keepConnected: value,
      isSaving: true,
      error: null,
    );

    try {
      final savedValue = await _repository.upsertKeepConnected(
        resolvedUserId,
        value,
      );
      state = state.copyWith(
        keepConnected: savedValue,
        isSaving: false,
      );
      if (savedValue) {
        await saveSavedLoginEmail(
          savedLoginEmail ?? Supabase.instance.client.auth.currentUser?.email,
        );
      } else {
        await clearSavedLoginEmail();
      }
      return true;
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao salvar manter conectado: $e');
      state = state.copyWith(
        keepConnected: previousValue,
        isSaving: false,
        error: 'Nao foi possivel salvar a preferencia.',
      );
      return false;
    }
  }

  Future<bool> shouldShowPrompt(String userId) async {
    await load(userId: userId);
    if (state.error != null) return false;
    await loadSavedLoginEmail();
    final wasAnswered = await _promptStorage.wasPromptAnswered(userId);
    if (!wasAnswered) return true;
    return state.keepConnected && !state.hasSavedLoginEmail;
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
    state = KeepConnectedState(savedLoginEmail: state.savedLoginEmail);
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
