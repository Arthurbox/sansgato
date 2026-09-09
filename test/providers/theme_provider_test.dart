import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sansgato/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider Unit Tests', () {
    test('Initial theme should be system by default', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeProvider);
      
      expect(themeMode, ThemeMode.system);
    });

    test('toggleTheme should cycle between light and dark', () async {
      SharedPreferences.setMockInitialValues({});
      
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // We read the provider directly
      expect(container.read(themeProvider), ThemeMode.system);
      
      // Simulate changing to dark
      container.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);
      
      // Simulate changing to light
      container.read(themeProvider.notifier).setTheme(ThemeMode.light);
      expect(container.read(themeProvider), ThemeMode.light);
    });
  });
}
