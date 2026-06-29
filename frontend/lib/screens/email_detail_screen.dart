import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../models/email.dart';
import '../widgets/app_navigation.dart';

class EmailDetailScreen extends StatefulWidget {
  final int emailId;

  const EmailDetailScreen({super.key, required this.emailId});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  Email? _email;
  bool _isLoading = true;
  bool _isSendingFeedback = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadEmailDetails();
  }

  Future<void> _loadEmailDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final email = await _apiClient.fetchEmailDetails(widget.emailId);
      if (!mounted) return;
      setState(() {
        _email = email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFeedback(String correctedCategory) async {
    if (_email == null) return;
    setState(() {
      _isSendingFeedback = true;
    });
    try {
      await _apiClient.postFeedback(_email!.id, correctedCategory);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved correction: $correctedCategory')),
      );
      setState(() {
        _email = Email(
          id: _email!.id,
          sender: _email!.sender,
          subject: _email!.subject,
          category: correctedCategory,
          confidence: _email!.confidence,
          summary: _email!.summary,
          preview: _email!.preview,
          body: _email!.body,
        );
        _isSendingFeedback = false;
      });
    } catch (e) {
      setState(() {
        _isSendingFeedback = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save feedback: ${e.toString()}')),
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return AppTheme.important;
      case 'normal':
        return AppTheme.normal;
      case 'ignored':
        return AppTheme.ignored;
      default:
        return AppTheme.secondary;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return AppTheme.important.withOpacity(0.06);
      case 'normal':
        return AppTheme.normal.withOpacity(0.06);
      case 'ignored':
        return AppTheme.ignored.withOpacity(0.12);
      default:
        return AppTheme.secondary.withOpacity(0.06);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartInboxAppBar(title: 'Email Details'),
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
                          'Failed to load email details.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEmailDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _email == null
                  ? const Center(child: Text('Email not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender & Date
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.12),
                                foregroundColor: AppTheme.primary,
                                child: const Icon(Icons.person),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _email!.sender,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Text(
                                      'to me',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          // Category Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getCategoryBgColor(_email!.category),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getCategoryColor(_email!.category).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.label,
                                      size: 16,
                                      color: _getCategoryColor(_email!.category),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _email!.category,
                                      style: TextStyle(
                                        color: _getCategoryColor(_email!.category),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${(_email!.confidence * 100).toInt()}% confidence',
                                      style: TextStyle(
                                        color: _getCategoryColor(_email!.category).withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Subject
                          Text(
                            _email!.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // AI Summary Section
                          if (_email!.summary.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.secondary.withOpacity(0.18)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 20, color: AppTheme.secondary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Summary',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _email!.summary,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.secondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Full Body Header
                          const Text(
                            'Email Body',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Full Body
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              _email!.body ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Feedback buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSendingFeedback ? null : () => _sendFeedback('Important'),
                                  icon: const Icon(Icons.star),
                                  label: const Text('Mark Important'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.important),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSendingFeedback ? null : () => _sendFeedback('Normal'),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Mark Normal'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.normal),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isSendingFeedback ? null : () => _sendFeedback('Ignored'),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  label: const Text('Mark Ignored'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ignored.withOpacity(0.12), foregroundColor: AppTheme.text),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}
