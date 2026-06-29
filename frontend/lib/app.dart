import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/ai_loading_screen.dart';
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
        return MaterialApp(
          title: 'SmartInbox AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          // Always start with the splash screen
          home: const SplashScreen(),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case AppNavigation.splash:
        page = const SplashScreen();
      case AppNavigation.login:
        page = const LoginScreen();
      case AppNavigation.aiLoading:
        page = const AiLoadingScreen();
      case AppNavigation.dailyBrief:
        page = const DailyBriefScreen();
      case AppNavigation.dashboard:
      case AppNavigation.inbox:
        page = const DashboardScreen();
      case AppNavigation.stats:
        page = const StatsScreen();
      case AppNavigation.settings:
        page = const SettingsScreen();
      case AppNavigation.feedback:
        page = const FeedbackScreen();
      case AppNavigation.evaluation:
        page = const EvaluationScreen();
      case AppNavigation.gmailSettings:
        page = const GmailSettingsScreen();
      default:
        page = const SplashScreen();
    }
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, a1, a2) => page,
      transitionsBuilder: (context, animation, a2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
