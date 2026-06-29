import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';

class AppNavigation {
  static const String splash = '/';
  static const String login = '/login';
  static const String aiLoading = '/ai-loading';
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
    final displayEmail =
        state.userEmail.isEmpty ? 'demo@example.com' : state.userEmail;
    final displayName = state.userName;
    final initials = displayName.isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : 'U';

    return Drawer(
      child: Column(
        children: [
          // Premium header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, Color(0xFFD93025)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App branding
                Row(
                  children: [
                    const Icon(
                      Icons.mark_email_unread,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SmartInbox AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 11,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'AI Demo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
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
                  label: 'Gmail Settings',
                  routeName: AppNavigation.gmailSettings,
                  currentRoute: currentRoute,
                ),
                _DrawerItem(
                  icon: Icons.feedback_outlined,
                  label: 'Feedback',
                  routeName: AppNavigation.feedback,
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red, size: 22),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Demo Mode',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            onTap: () => AppNavigation.logout(context),
          ),
          const SizedBox(height: 8),
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
