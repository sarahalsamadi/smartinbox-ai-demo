import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _userName = 'User';
  String get userName => _userName;

  String _userEmail = '';
  String get userEmail => _userEmail;

  String _classifier = 'rules';
  String get classifier => _classifier;

  void login({required String name, required String email}) {
    final trimmedName = name.trim();
    _userName = trimmedName.isEmpty ? 'User' : trimmedName;
    _userEmail = email.trim();
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = 'User';
    _userEmail = '';
    notifyListeners();
  }

  void setClassifier(String value) {
    if (value == 'rules' || value == 'ml') {
      _classifier = value;
      notifyListeners();
    }
  }
}
