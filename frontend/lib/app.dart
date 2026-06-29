import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/daily_brief_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/evaluation_screen.dart';
import 'screens/gmail_settings_screen.dart';
import 'widgets/app_navigation.dart';

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
          home: state.isLoggedIn
              ? const DailyBriefScreen()
              : const LoginScreen(),
          routes: {
            AppNavigation.login: (context) => const LoginScreen(),
            AppNavigation.dailyBrief: (context) => const DailyBriefScreen(),
            AppNavigation.dashboard: (context) => const DashboardScreen(),
            AppNavigation.inbox: (context) => const DashboardScreen(),
            AppNavigation.stats: (context) => const StatsScreen(),
            AppNavigation.settings: (context) => const SettingsScreen(),
            AppNavigation.feedback: (context) => const FeedbackScreen(),
            AppNavigation.evaluation: (context) => const EvaluationScreen(),
            AppNavigation.gmailSettings: (context) =>
                const GmailSettingsScreen(),
          },
        );
      },
    );
  }
}
