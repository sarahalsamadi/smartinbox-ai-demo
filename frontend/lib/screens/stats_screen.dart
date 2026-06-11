import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiClient _apiClient = ApiClient();
  EmailStats? _stats;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final stats = await _apiClient.fetchStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(
              icon,
              size: 48,
              color: color.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox Statistics'),
      ),
      body: _isLoading
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
                          'Failed to load statistics.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStats,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _stats == null
                  ? const Center(child: Text('No stats data found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email Distribution',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Visual breakdown of your emails by priority category.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStatCard(
                            title: 'TOTAL EMAILS',
                            count: _stats!.total,
                            icon: Icons.email,
                            color: Colors.amber.shade900,
                            bgColor: Colors.amber.shade50.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            title: 'IMPORTANT EMAILS',
                            count: _stats!.important,
                            icon: Icons.label_important,
                            color: Colors.red.shade800,
                            bgColor: Colors.red.shade50.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            title: 'NORMAL EMAILS',
                            count: _stats!.normal,
                            icon: Icons.mail_outline,
                            color: Colors.blue.shade800,
                            bgColor: Colors.blue.shade50.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            title: 'IGNORED EMAILS',
                            count: _stats!.ignored,
                            icon: Icons.delete_outline,
                            color: Colors.grey.shade800,
                            bgColor: Colors.grey.shade100,
                          ),
                        ],
                      ),
                    ),
    );
  }
}
