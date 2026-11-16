import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

enum AppLanguage { english, filipino }

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    unawaited(_load());
  }

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;
  Object? _loadError;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  Object? get loadError => _loadError;

  Future<void> setThemeMode(ThemeMode value) async {
    final oldValue = _themeMode;
    _themeMode = value;
    notifyListeners();
    try {
      await _save();
    } catch (_) {
      _themeMode = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setLanguage(AppLanguage value) async {
    final oldValue = _language;
    _language = value;
    notifyListeners();
    try {
      await _save();
    } catch (_) {
      _language = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<File> _settingsFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}settings.json');
  }

  Future<void> _load() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Settings must be a JSON object.');
      }

      final themeName = json['themeMode'];
      final languageName = json['language'];
      final theme = ThemeMode.values.where((value) => value.name == themeName);
      final language = AppLanguage.values.where(
        (value) => value.name == languageName,
      );
      if (theme.isEmpty || language.isEmpty) {
        throw const FormatException('Settings contain an unsupported option.');
      }

      _themeMode = theme.first;
      _language = language.first;
      notifyListeners();
    } catch (error) {
      _loadError = error;
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'themeMode': _themeMode.name, 'language': _language.name}),
    );
  }
}
