import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLightMode => !_isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    if (_isDarkMode == isDark) {
      return;
    }
    _isDarkMode = isDark;
    notifyListeners();
  }
}
