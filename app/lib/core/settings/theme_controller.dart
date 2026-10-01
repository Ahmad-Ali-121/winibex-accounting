import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'preferences.dart';

part 'theme_controller.g.dart';

const _key = 'theme_mode';

/// System default on first load, user override saved. UI guide, Visual design.
@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }

  /// Cycles system, light, dark. One button rather than a menu, because this
  /// is a preference people set once.
  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await set(next);
  }
}
