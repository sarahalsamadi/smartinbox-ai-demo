import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/daily_brief.dart';
import '../widgets/app_navigation.dart';
import '../widgets/ai_widgets.dart';
import 'email_detail_screen.dart';

class DailyBriefScreen extends StatefulWidget {
  const DailyBriefScreen({super.key});

  @override
  State<DailyBriefScreen> createState() => _DailyBriefScreenState();
}

class _DailyBriefScreenState extends State<DailyBriefScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  DailyBrief? _brief;
  bool _isLoading = true;
  String _error = '';

  late final AnimationController _greetingCtrl;
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;

  @override
  void initState() {
    super.initState();
    _greetingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _greetingFade =
        CurvedAnimation(parent: _greetingCtrl, curve: Curves.easeOut);
    _greetingSlide = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _greetingCtrl, curve: Curves.easeOut));
    _loadBrief();
  }

  @override
  void dispose() {
    _greetingCtrl.dispose();
    super.dispose();
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
      _greetingCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openInbox() {
    Navigator.pushReplacementNamed(context, AppNavigation.dashboard);
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

  String _getGreetingWord() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final userName = AppState().userName;
    return Scaffold(
      appBar: SmartInboxAppBar(
        title: 'Smart Daily Brief',
        isRoot: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadBrief,
          ),
        ],
      ),
      drawer: const SmartInboxDrawer(currentRoute: AppNavigation.dailyBrief),
      body: _isLoading
          ? _buildLoadingState()
          : _error.isNotEmpty
          ? _buildErrorState()
          : _brief == null
          ? const EmptyStateWidget(
              message: 'Daily brief is unavailable.',
              icon: Icons.wb_sunny_outlined,
            )
          : RefreshIndicator(
              onRefresh: _loadBrief,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  FadeTransition(
                    opacity: _greetingFade,
                    child: SlideTransition(
                      position: _greetingSlide,
                      child: _buildGreeting(userName),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    index: 0,
                    child: _buildKpiGrid(_brief!),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    index: 1,
                    child: _buildTopPriorityCard(_brief!),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    index: 2,
                    child: _buildSuggestedActionCard(_brief!),
                  ),
                  const SizedBox(height: 16),
                  AnimatedCard(
                    index: 3,
                    child: _buildProductivityWidget(_brief!),
                  ),
                  const SizedBox(height: 20),
                  AnimatedCard(
                    index: 4,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openInbox,
                        icon: const Icon(Icons.inbox),
                        label: const Text('Open Inbox'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 16),
          Text(
            'Loading your daily brief…',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withOpacity(0.08),
            AppTheme.secondary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny, color: AppTheme.warning, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreetingWord()}, $userName! 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _brief?.productivityMessage ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.35,
                    fontSize: 13,
                  ),
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
        '📨 New Emails',
        brief.totalEmails.toString(),
        Icons.mail_outline,
        AppTheme.secondary,
      ),
      _KpiData(
        '🔥 High Priority',
        brief.urgentEmails.toString(),
        Icons.priority_high,
        AppTheme.important,
      ),
      _KpiData(
        '✅ Normal',
        brief.normalEmails.toString(),
        Icons.check_circle_outline,
        AppTheme.success,
      ),
      _KpiData(
        '🔕 Ignored',
        brief.ignoredEmails.toString(),
        Icons.remove_circle_outline,
        AppTheme.ignored,
      ),
      _KpiData(
        '⏱ Time Saved',
        '${brief.estimatedTimeSavedMinutes} min',
        Icons.schedule,
        AppTheme.success,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Today at a Glance',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
              ),
            ),
            const Spacer(),
            const AiBadge.analyzed(),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kpis.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 5 : 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 1.4 : 1.0,
              ),
              itemBuilder: (context, index) => AnimatedStatCard(
                icon: kpis[index].icon,
                color: kpis[index].color,
                value: kpis[index].value,
                label: kpis[index].label,
                index: index,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopPriorityCard(DailyBrief brief) {
    final topEmail = brief.topPriorityEmail;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.important.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.important.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: topEmail == null
            ? Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 24),
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.important.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: AppTheme.important,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Today's Most Important Email",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.text,
                        ),
                      ),
                      const Spacer(),
                      // Priority score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.important,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(topEmail.confidence * 100).round()}% priority',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Sender
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.secondary.withOpacity(0.1),
                        child: Text(
                          topEmail.sender.isNotEmpty
                              ? topEmail.sender[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          topEmail.sender,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Subject
                  Text(
                    topEmail.subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Summary with badge
                  const AiBadge.summary(),
                  const SizedBox(height: 6),
                  Text(
                    topEmail.summary,
                    style: TextStyle(
                      height: 1.5,
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const AiBadge(label: 'AI Suggested Action', icon: Icons.touch_app),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _openTopPriorityEmail,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open Email'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.important,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuggestedActionCard(DailyBrief brief) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tips_and_updates,
              color: AppTheme.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI Suggested Action',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const AiBadge.suggested(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  brief.suggestedAction,
                  style: TextStyle(
                    height: 1.4,
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityWidget(DailyBrief brief) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.success.withOpacity(0.06),
            AppTheme.secondary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: AppTheme.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Today's Productivity",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProductivityStat(
                  icon: Icons.schedule,
                  color: AppTheme.success,
                  value: '${brief.estimatedTimeSavedMinutes} min',
                  label: 'Time Saved',
                  index: 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProductivityStat(
                  icon: Icons.mail_outline,
                  color: AppTheme.secondary,
                  value: brief.totalEmails.toString(),
                  label: 'Emails Processed',
                  index: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProductivityStat(
                  icon: Icons.auto_awesome,
                  color: AppTheme.warning,
                  value: '${brief.urgentEmails + brief.normalEmails}',
                  label: 'AI Suggestions',
                  index: 2,
                ),
              ),
            ],
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load the daily brief',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ensure FastAPI backend is running.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadBrief,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductivityStat extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final int index;

  const _ProductivityStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.index,
  });

  @override
  State<_ProductivityStat> createState() => _ProductivityStatState();
}

class _ProductivityStatState extends State<_ProductivityStat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 200 + widget.index * 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(height: 6),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
