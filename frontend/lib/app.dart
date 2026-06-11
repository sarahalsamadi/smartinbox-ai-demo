import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

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
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber,
              primary: Colors.amber.shade700,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          home: state.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/stats': (context) => const StatsScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}
