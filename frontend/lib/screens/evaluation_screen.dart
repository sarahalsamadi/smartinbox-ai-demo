import 'package:flutter/material.dart';
import '../core/api_client.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> _loadAll() async {
    final evaluation = await _apiClient.fetchEvaluation();
    final differences = await _apiClient.fetchEvaluationDifferences(limit: 200);
    return {'evaluation': evaluation, 'differences': differences};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Evaluation')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load evaluation: ${snapshot.error}'));
          }
          final data = snapshot.data ?? {};
          final eval = data['evaluation'] as Map<String, dynamic>? ?? {};
          final diffs = data['differences'] as Map<String, dynamic>? ?? {};
          final items = diffs['items'] as List<dynamic>? ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricCard('Total Samples', '${eval['total_samples'] ?? 0}'),
                    _metricCard('Accuracy', '${((eval['accuracy_against_weak_labels'] ?? 0.0) * 100).toStringAsFixed(2)}%'),
                    _metricCard('Matching', '${eval['matching_predictions'] ?? 0}'),
                    _metricCard('Different', '${eval['different_predictions'] ?? 0}'),
                    _metricCard('Feedback', '${eval['feedback_count'] ?? 0}'),
                    _metricCard('Last Retrained', '${eval['last_retrained_at'] ?? 'never'}'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Class Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildDistribution(eval['class_distribution'] as Map<String, dynamic>? ?? {}),
                const SizedBox(height: 16),
                const Text('Differences (Rules vs ML)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                items.isEmpty
                    ? const Text('No differences found.')
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final it = items[index] as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(child: Text('${it['id'] ?? ''}')),
                            title: Text(it['subject'] ?? '(no subject)'),
                            subtitle: Text('${it['rule_category']} → ${it['ml_category']}'),
                            trailing: Text('${((it['ml_confidence'] ?? 0.0) * 100).toInt()}%'),
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistribution(Map<String, dynamic> dist) {
    if (dist.isEmpty) return const Text('No predictions yet.');
    final entries = dist.entries.toList();
    return Wrap(
      spacing: 8,
      children: entries.map((e) => Chip(label: Text('${e.key}: ${e.value}'))).toList(),
    );
  }
}
