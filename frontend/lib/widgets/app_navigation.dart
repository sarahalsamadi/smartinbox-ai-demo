import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';

class AppNavigation {
  static const String login = '/login';
  static const String dailyBrief = '/daily-brief';
  static const String dashboard = '/dashboard';
  static const String inbox = '/inbox';
  static const String stats = '/stats';
  static const String evaluation = '/evaluation';
  static const String settings = '/settings';
  static const String gmailSettings = '/gmail-settings';
  static const String feedback = '/feedback';

  static void openRoot(BuildContext context, String routeName) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    Navigator.pop(context);
    if (currentRoute == routeName) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  static void logout(BuildContext context) {
    Navigator.pop(context);
    AppState().logout();
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }
}

class SmartInboxAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double iconSize = 24;

  final String title;
  final bool isRoot;
  final bool showBackButton;
  final List<Widget>? actions;

  const SmartInboxAppBar({
    super.key,
    required this.title,
    this.isRoot = false,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: AppTheme.appBarHeight,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 56,
      leading: _buildLeading(context),
      titleSpacing: 0,
      title: Row(
        children: [
          const Icon(Icons.mark_email_unread, size: iconSize),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (isRoot) {
      return Builder(
        builder: (context) => IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu, size: iconSize),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      );
    }

    if (!showBackButton) return null;

    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back, size: iconSize),
      onPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          Navigator.pushReplacementNamed(context, AppNavigation.dailyBrief);
        }
      },
    );
  }
}

class SmartInboxDrawer extends StatelessWidget {
  final String currentRoute;

  const SmartInboxDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mark_email_unread, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'SmartInbox AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  state.userEmail.isEmpty ? 'demo@example.com' : state.userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _DrawerItem(
            icon: Icons.home_outlined,
            label: 'Dashboard',
            routeName: AppNavigation.dashboard,
            currentRoute: currentRoute,
          ),
          _DrawerItem(
            icon: Icons.wb_sunny_outlined,
            label: 'Smart Daily Brief',
            routeName: AppNavigation.dailyBrief,
            currentRoute: currentRoute,
          ),
          _DrawerItem(
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            routeName: AppNavigation.inbox,
            currentRoute: currentRoute,
          ),
          _DrawerItem(
            icon: Icons.bar_chart,
            label: 'Statistics',
            routeName: AppNavigation.stats,
            currentRoute: currentRoute,
          ),
          _DrawerItem(
            icon: Icons.trending_up,
            label: 'Evaluation',
            routeName: AppNavigation.evaluation,
            currentRoute: currentRoute,
          ),
          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            routeName: AppNavigation.settings,
            currentRoute: currentRoute,
          ),
          _DrawerItem(
            icon: Icons.alternate_email,
            label: 'Gmail',
            routeName: AppNavigation.gmailSettings,
            currentRoute: currentRoute,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 24),
            title: const Text(
              'Logout (Demo)',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => AppNavigation.logout(context),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;
  final String currentRoute;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.routeName,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final selected = routeName == currentRoute ||
        (routeName == AppNavigation.inbox &&
            currentRoute == AppNavigation.dashboard);
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label),
      selected: selected,
      selectedTileColor: AppTheme.primary.withOpacity(0.08),
      selectedColor: AppTheme.primary,
      onTap: () => AppNavigation.openRoot(
        context,
        routeName == AppNavigation.inbox ? AppNavigation.dashboard : routeName,
      ),
    );
  }
}
