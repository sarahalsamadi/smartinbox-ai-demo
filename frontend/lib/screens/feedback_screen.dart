import 'package:flutter/material.dart';
import '../core/api_client.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> _loadFeedback() async {
    return await _apiClient.fetchFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: FutureBuilder<List<dynamic>>(
        future: _loadFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load feedback: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No feedback saved yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (context, _) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(child: Text(item['email_id'].toString())),
                title: Text('Corrected: ${item['corrected_category']}'),
                subtitle: Text('Predicted: ${item['predicted_category']} • ${item['corrected_at']}'),
              );
            },
          );
        },
      ),
    );
  }
}
