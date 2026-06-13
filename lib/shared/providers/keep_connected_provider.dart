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
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final bool keepConnected;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  KeepConnectedState copyWith({
    bool? keepConnected,
    bool? isLoading,
    bool? isSaving,
    Object? error = _keepConnectedUnset,
  }) {
    return KeepConnectedState(
      keepConnected: keepConnected ?? this.keepConnected,
      isLoading: isLoading ?? this.isLoading,
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
    } on Exception catch (e) {
      debugPrint('[UserSettings] Erro ao carregar manter conectado: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Nao foi possivel carregar a preferencia.',
      );
    }
  }

  Future<bool> setKeepConnected(
    bool value, {
    String? userId,
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
    final wasAnswered = await _promptStorage.wasPromptAnswered(userId);
    return !wasAnswered;
  }

  Future<bool> answerPrompt(String userId, bool keepConnected) async {
    final saved = await setKeepConnected(
      keepConnected,
      userId: userId,
    );
    if (!saved) return false;

    await _promptStorage.markPromptAnswered(userId);
    return true;
  }

  void clearSessionState() {
    state = const KeepConnectedState();
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
