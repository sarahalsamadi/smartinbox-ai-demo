import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/evaluation_screen.dart';
import 'screens/gmail_settings_screen.dart';

class SmartInboxApp extends StatelessWidget {
  const SmartInboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState(),
      builder: (context, child) {
        final state = AppState();
        return MaterialApp(
          title: 'SmartInbox AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: state.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/stats': (context) => const StatsScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/feedback': (context) => const FeedbackScreen(),
            '/evaluation': (context) => const EvaluationScreen(),
            '/gmail-settings': (context) => const GmailSettingsScreen(),
          },
        );
      },
    );
  }
}
