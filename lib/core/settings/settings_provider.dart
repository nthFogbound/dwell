import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

enum AppLanguage { english, filipino }

enum MissedCardRepeatGap {
  immediately(0),
  afterTwoCards(2),
  afterFiveCards(5);

  const MissedCardRepeatGap(this.cardGap);

  final int cardGap;
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    unawaited(_load());
  }

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.english;
  MissedCardRepeatGap _missedCardRepeatGap = MissedCardRepeatGap.afterTwoCards;
  int? _lastTopicId;
  Object? _loadError;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  MissedCardRepeatGap get missedCardRepeatGap => _missedCardRepeatGap;
  int? get lastTopicId => _lastTopicId;
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

  Future<void> setMissedCardRepeatGap(MissedCardRepeatGap value) async {
    final oldValue = _missedCardRepeatGap;
    _missedCardRepeatGap = value;
    notifyListeners();
    try {
      await _save();
    } catch (_) {
      _missedCardRepeatGap = oldValue;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setLastTopicId(int? value) async {
    final oldValue = _lastTopicId;
    _lastTopicId = value;
    try {
      await _save();
    } catch (_) {
      _lastTopicId = oldValue;
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
      final repeatGapName = json['missedCardRepeatGap'];
      final theme = ThemeMode.values.where((value) => value.name == themeName);
      final language = AppLanguage.values.where(
        (value) => value.name == languageName,
      );
      final repeatGap = MissedCardRepeatGap.values.where(
        (value) => value.name == repeatGapName,
      );
      if (theme.isEmpty ||
          language.isEmpty ||
          (repeatGapName != null && repeatGap.isEmpty)) {
        throw const FormatException('Settings contain an unsupported option.');
      }

      _themeMode = theme.first;
      _language = language.first;
      if (repeatGap.isNotEmpty) _missedCardRepeatGap = repeatGap.first;
      final lastTopicId = json['lastTopicId'];
      _lastTopicId = lastTopicId is int ? lastTopicId : null;
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
      jsonEncode({
        'themeMode': _themeMode.name,
        'language': _language.name,
        'missedCardRepeatGap': _missedCardRepeatGap.name,
        'lastTopicId': _lastTopicId,
      }),
    );
  }
}
