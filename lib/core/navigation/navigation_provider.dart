import 'package:flutter/foundation.dart';

/// The app's top-level sections, in the same order as the navigation rail.
enum AppSection { courses, flashcards, quiz, progress }

class NavigationProvider extends ChangeNotifier {
  AppSection _current = AppSection.courses;

  AppSection get current => _current;

  void select(AppSection section) {
    if (section == _current) return; // Nothing changed, so don't rebuild.
    _current = section;
    notifyListeners(); // Tells Provider to rebuild widgets that use this.
  }
}
