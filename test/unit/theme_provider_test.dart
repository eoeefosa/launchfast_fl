import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campuschow/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider Unit Tests', () {
    test('should initialize with default system theme if no value stored', () async {
      SharedPreferences.setMockInitialValues({});
      
      final provider = ThemeProvider();
      
      // Allow async SharedPreferences load to complete
      await Future.delayed(Duration.zero);

      expect(provider.themeMode, equals(ThemeMode.system));
      expect(provider.isSystem, isTrue);
      expect(provider.isDark, isFalse);
      expect(provider.isLight, isFalse);
    });

    test('should initialize with stored dark theme mode', () async {
      SharedPreferences.setMockInitialValues({
        'launch-fast-theme-mode': 'dark',
      });

      final provider = ThemeProvider();
      await Future.delayed(Duration.zero);

      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(provider.isDark, isTrue);
      expect(provider.isLight, isFalse);
      expect(provider.isSystem, isFalse);
    });

    test('should initialize with stored light theme mode', () async {
      SharedPreferences.setMockInitialValues({
        'launch-fast-theme-mode': 'light',
      });

      final provider = ThemeProvider();
      await Future.delayed(Duration.zero);

      expect(provider.themeMode, equals(ThemeMode.light));
      expect(provider.isLight, isTrue);
      expect(provider.isDark, isFalse);
      expect(provider.isSystem, isFalse);
    });

    test('should transition theme modes and persist the new mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final provider = ThemeProvider();
      await Future.delayed(Duration.zero);
      expect(provider.themeMode, equals(ThemeMode.system));

      // Change to dark mode
      var listenerCalled = false;
      provider.addListener(() {
        listenerCalled = true;
      });

      await provider.setTheme(ThemeMode.dark);
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(listenerCalled, isTrue);
      expect(prefs.getString('launch-fast-theme-mode'), equals('dark'));

      // Reset listener flag and change to light mode
      listenerCalled = false;
      await provider.setTheme(ThemeMode.light);
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(listenerCalled, isTrue);
      expect(prefs.getString('launch-fast-theme-mode'), equals('light'));

      // Change back to system mode
      listenerCalled = false;
      await provider.setTheme(ThemeMode.system);
      expect(provider.themeMode, equals(ThemeMode.system));
      expect(listenerCalled, isTrue);
      expect(prefs.getString('launch-fast-theme-mode'), equals('system'));
    });
  });
}
