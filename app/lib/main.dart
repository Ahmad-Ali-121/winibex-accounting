import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/settings/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read once at startup and hand it to the providers, so nothing in the app
  // has to await storage just to know which theme to draw.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WinibexApp(),
    ),
  );
}
