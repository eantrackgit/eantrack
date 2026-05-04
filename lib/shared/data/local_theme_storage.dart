import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const localThemeStorageKey = 'eantrack.theme';

class LocalThemeStorage {
  const LocalThemeStorage();

  Future<ThemeMode?> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return themeModeFromStorageValue(preferences.getString(localThemeStorageKey));
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      localThemeStorageKey,
      themeModeToStorageValue(mode),
    );
  }
}

ThemeMode? themeModeFromStorageValue(String? value) {
  switch (value?.trim().toLowerCase()) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return null;
  }
}

String themeModeToStorageValue(ThemeMode mode) {
  return mode == ThemeMode.dark ? 'dark' : 'light';
}
