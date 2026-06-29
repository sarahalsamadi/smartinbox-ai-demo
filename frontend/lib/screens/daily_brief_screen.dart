import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/daily_brief.dart';
import 'email_detail_screen.dart';

class DailyBriefScreen extends StatefulWidget {
  const DailyBriefScreen({super.key});

  @override
  State<DailyBriefScreen> createState() => _DailyBriefScreenState();
}

class _DailyBriefScreenState extends State<DailyBriefScreen> {
  final ApiClient _apiClient = ApiClient();
  DailyBrief? _brief;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadBrief();
  }

  Future<void> _loadBrief() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final brief = await _apiClient.fetchDailyBrief();
      if (!mounted) return;
      setState(() {
        _brief = brief;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openInbox() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _openTopPriorityEmail() {
    final topEmail = _brief?.topPriorityEmail;
    if (topEmail == null || topEmail.id == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(emailId: topEmail.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = AppState().userName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Brief'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadBrief,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _buildErrorState()
          : _brief == null
          ? const Center(child: Text('Daily brief is unavailable.'))
          : RefreshIndicator(
              onRefresh: _loadBrief,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGreeting(userName),
                  const SizedBox(height: 16),
                  _buildKpiGrid(_brief!),
                  const SizedBox(height: 16),
                  _buildTopPriorityCard(_brief!),
                  const SizedBox(height: 16),
                  _buildSuggestedActionCard(_brief!),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openInbox,
                      icon: const Icon(Icons.inbox),
                      label: const Text('Go to Inbox'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.wb_sunny_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, $userName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _brief?.productivityMessage ?? '',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(DailyBrief brief) {
    final kpis = [
      _KpiData(
        'Total Emails',
        brief.totalEmails.toString(),
        Icons.mail,
        AppTheme.secondary,
      ),
      _KpiData(
        'Urgent Emails',
        brief.urgentEmails.toString(),
        Icons.priority_high,
        AppTheme.important,
      ),
      _KpiData(
        'Normal Emails',
        brief.normalEmails.toString(),
        Icons.check_circle_outline,
        AppTheme.normal,
      ),
      _KpiData(
        'Ignored Emails',
        brief.ignoredEmails.toString(),
        Icons.remove_circle_outline,
        AppTheme.ignored,
      ),
      _KpiData(
        'Time Saved',
        '${brief.estimatedTimeSavedMinutes} min',
        Icons.schedule,
        AppTheme.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 5 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: isWide ? 1.45 : 1.35,
          ),
          itemBuilder: (context, index) => _buildKpiCard(kpis[index]),
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, color: data.color, size: 24),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPriorityCard(DailyBrief brief) {
    final topEmail = brief.topPriorityEmail;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: topEmail == null
            ? Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.success),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No urgent email is waiting for review.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: AppTheme.important),
                      const SizedBox(width: 8),
                      const Text(
                        'Top Priority Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(topEmail.confidence * 100).round()}%',
                        style: TextStyle(
                          color: AppTheme.important,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    topEmail.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topEmail.sender,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Text(topEmail.summary, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _openTopPriorityEmail,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Email'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuggestedActionCard(DailyBrief brief) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tips_and_updates, color: AppTheme.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suggested Action',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    brief.suggestedAction,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load the daily brief.\nEnsure FastAPI backend is running.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadBrief, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final state = AppState();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'SmartInbox AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.userEmail.isEmpty
                      ? 'demo@example.com'
                      : state.userEmail,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Daily Brief'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.inbox),
            title: const Text('Inbox'),
            onTap: () {
              Navigator.pop(context);
              _openInbox();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/stats');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Evaluation'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/evaluation');
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedback'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/feedback');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              AppState().logout();
            },
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _KpiData(this.label, this.value, this.icon, this.color);
}
