import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controla o modo de tema ativo (claro/escuro).
///
/// Por ora persiste apenas em memória. Para futura persistência:
/// substituir [StateProvider] por um [AsyncNotifierProvider] que
/// lê/salva em SharedPreferences ou Supabase user_settings.
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.light,
);
