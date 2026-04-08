// ignore_for_file: deprecated_member_use

import 'dart:html' as html;

import 'password_recovery_cooldown_storage_base.dart';

class _WebCooldownStorage implements CooldownStorage {
  @override
  int? readInt(String key) {
    final raw = html.window.localStorage[key];
    return raw == null ? null : int.tryParse(raw);
  }

  @override
  String? readString(String key) => html.window.localStorage[key];

  @override
  void remove(String key) {
    html.window.localStorage.remove(key);
  }

  @override
  void writeInt(String key, int value) {
    html.window.localStorage[key] = value.toString();
  }

  @override
  void writeString(String key, String value) {
    html.window.localStorage[key] = value;
  }
}

CooldownStorage createCooldownStorageImpl() => _WebCooldownStorage();
