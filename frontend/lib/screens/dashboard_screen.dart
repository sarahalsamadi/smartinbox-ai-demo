import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/email.dart';
import '../widgets/app_navigation.dart';
import '../widgets/email_card.dart';
import '../widgets/ai_widgets.dart';
import 'email_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<Email> _emails = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = 'All';

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerCtrl.forward();

    AppState().addListener(_onAppStateChanged);
    _loadEmails();
  }

  @override
  void dispose() {
    AppState().removeListener(_onAppStateChanged);
    _searchController.dispose();
    _headerCtrl.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) _loadEmails();
  }

  Future<void> _loadEmails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final emails = await _apiClient.fetchEmails(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        search: _searchController.text,
        classifier: AppState().classifier,
      );
      setState(() {
        _emails = emails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartInboxAppBar(
        title: 'Inbox',
        isRoot: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadEmails,
          ),
        ],
      ),
      drawer: const SmartInboxDrawer(currentRoute: AppNavigation.dashboard),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: _buildHeader(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _error.isNotEmpty
                ? _buildErrorState()
                : _emails.isEmpty
                ? EmptyStateWidget(
                    message: 'No emails today',
                    subtitle:
                        'Your inbox is clear — AI has processed everything.',
                    icon: Icons.inbox_outlined,
                    color: AppTheme.secondary,
                  )
                : RefreshIndicator(
                    onRefresh: _loadEmails,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _emails.length,
                      itemBuilder: (context, index) {
                        final email = _emails[index];
                        return AnimatedCard(
                          index: index,
                          delay: const Duration(milliseconds: 80),
                          child: EmailCard(
                            email: email,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EmailDetailScreen(emailId: email.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sender, subject, body…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppTheme.secondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadEmails();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: const BorderSide(
                    color: AppTheme.secondary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _loadEmails(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: ['All', 'Important', 'Normal', 'Ignored'].map(
                (category) {
                  final isSelected = _selectedCategory == category;
                  Color chipColor;
                  switch (category) {
                    case 'Important':
                      chipColor = AppTheme.important;
                    case 'Normal':
                      chipColor = AppTheme.success;
                    case 'Ignored':
                      chipColor = AppTheme.ignored;
                    default:
                      chipColor = AppTheme.secondary;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                            _loadEmails();
                          }
                        },
                        selectedColor: chipColor.withOpacity(0.12),
                        checkmarkColor: chipColor,
                        labelStyle: TextStyle(
                          color: isSelected ? chipColor : Colors.grey.shade600,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? chipColor.withOpacity(0.4)
                              : Colors.grey.shade200,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          // Classifier + AI badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  'Classifier: ${AppState().classifier.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  const AiBadge.analyzed(),
                const Spacer(),
                if (!_isLoading)
                  Text(
                    '${_emails.length} emails',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
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
              'Failed to load emails',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Ensure FastAPI backend is running.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadEmails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
