import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_state.dart';
import '../models/email.dart';
import '../widgets/email_card.dart';
import 'email_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<Email> _emails = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    AppState().addListener(_onAppStateChanged);
    _loadEmails();
  }

  @override
  void dispose() {
    AppState().removeListener(_onAppStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadEmails();
    }
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
      appBar: AppBar(
        title: const Text(
          'SmartInbox',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmails,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber.shade700),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'SmartInbox AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'demo@example.com',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Inbox'),
              selected: true,
              onTap: () => Navigator.pop(context),
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
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sender, subject, body...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadEmails();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _loadEmails(),
            ),
          ),
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: ['All', 'Important', 'Normal', 'Ignored'].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _loadEmails();
                      }
                    },
                    selectedColor: Colors.amber.shade200,
                    checkmarkColor: Colors.amber.shade900,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Status bar showing active classifier
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(Icons.psychology, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Classifier: ${AppState().classifier.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Emails list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load emails.\nEnsure FastAPI backend is running.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadEmails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _emails.isEmpty
                        ? const Center(
                            child: Text('No emails found in this category.'),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadEmails,
                            child: ListView.builder(
                              itemCount: _emails.length,
                              itemBuilder: (context, index) {
                                final email = _emails[index];
                                return EmailCard(
                                  email: email,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EmailDetailScreen(emailId: email.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
