import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/email.dart';

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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return Colors.red.shade700;
      case 'normal':
        return Colors.blue.shade700;
      case 'ignored':
        return Colors.grey.shade600;
      default:
        return Colors.teal.shade700;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category.toLowerCase()) {
      case 'important':
        return Colors.red.shade50;
      case 'normal':
        return Colors.blue.shade50;
      case 'ignored':
        return Colors.grey.shade100;
      default:
        return Colors.teal.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Details'),
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
                                backgroundColor: Colors.amber.shade100,
                                foregroundColor: Colors.amber.shade800,
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
                                color: Colors.amber.shade50.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 20, color: Colors.amber.shade800),
                                      const SizedBox(width: 8),
                                      Text(
                                        'AI Summary',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _email!.summary,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.amber.shade900,
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
                        ],
                      ),
                    ),
    );
  }
}
