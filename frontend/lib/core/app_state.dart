import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _classifier = 'rules';
  String get classifier => _classifier;

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void setClassifier(String value) {
    if (value == 'rules' || value == 'ml') {
      _classifier = value;
      notifyListeners();
    }
  }
}
