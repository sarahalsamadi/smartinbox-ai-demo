import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../widgets/app_navigation.dart';

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

  String formatDateTime(String? value) {
    if (value == null) return 'Never';
    try {
      final dt = DateTime.parse(value).toUtc();
      final fmt = DateFormat('dd MMM yyyy, HH:mm');
      return fmt.format(dt);
    } catch (e) {
      return 'Never';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartInboxAppBar(title: 'Evaluation', isRoot: true),
      drawer: const SmartInboxDrawer(currentRoute: AppNavigation.evaluation),
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
                    _metricCard('Accuracy', '${((eval['accuracy_against_weak_labels'] ?? 0.0) * 100).toStringAsFixed(2)}%'),
                    _metricCard('Feedback', '${eval['feedback_count'] ?? 0}'),
                    _metricCard('Last Retrained', formatDateTime(eval['last_retrained_at'] as String?)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Class Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildDistribution(eval['class_distribution'] as Map<String, dynamic>? ?? {}),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Advanced Evaluation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  initiallyExpanded: false,
                  children: [
                    const SizedBox(height: 8),
                    const Text('Confusion Matrix', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildConfusionMatrix(eval['confusion_matrix'] as Map<String, dynamic>? ?? {}),
                    const SizedBox(height: 16),
                    const Text('Per-Class Metrics', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildPerClassTable(eval['per_class'] as Map<String, dynamic>? ?? {}),
                    const SizedBox(height: 12),
                  ],
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.secondary.withOpacity(0.12))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: AppTheme.text.withOpacity(0.6))),
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
      children: entries
          .map((e) => Chip(
                label: Text('${e.key}: ${e.value}'),
                backgroundColor: AppTheme.secondary.withOpacity(0.06),
                labelStyle: TextStyle(color: AppTheme.secondary),
              ))
          .toList(),
    );
  }

  Widget _buildConfusionMatrix(Map<String, dynamic> cm) {
    if (cm.isEmpty) return const Text('No confusion matrix available.');
    final labels = (cm['labels'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final matrix = (cm['matrix'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [DataColumn(label: Text('Actual / Predicted'))] + labels.map((l) => DataColumn(label: Text(l))).toList(),
        rows: List<DataRow>.generate(labels.length, (i) {
          final row = (matrix.length > i) ? (matrix[i] as List<dynamic>) : [];
          final cells = <DataCell>[DataCell(Text(labels[i]))];
          for (var j = 0; j < labels.length; j++) {
            final val = (row.length > j) ? row[j].toString() : '0';
            cells.add(DataCell(Text(val)));
          }
          return DataRow(cells: cells);
        }),
      ),
    );
  }

  Widget _buildPerClassTable(Map<String, dynamic> perClass) {
    if (perClass.isEmpty) return const Text('No per-class metrics available.');
    final labels = perClass.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Precision')),
          DataColumn(label: Text('Recall')),
          DataColumn(label: Text('F1')),
          DataColumn(label: Text('Support')),
        ],
        rows: labels.map((lbl) {
          final entry = perClass[lbl] as Map<String, dynamic>? ?? {};
          final precision = (entry['precision'] as num?)?.toDouble() ?? 0.0;
          final recall = (entry['recall'] as num?)?.toDouble() ?? 0.0;
          final f1 = (entry['f1'] as num?)?.toDouble() ?? 0.0;
          final support = (entry['support'] as int?) ?? (entry['support'] as num?)?.toInt() ?? 0;
          String pct(double v) => '${(v * 100).toStringAsFixed(2)}%';
          return DataRow(cells: [
            DataCell(Text(lbl)),
            DataCell(Text(pct(precision))),
            DataCell(Text(pct(recall))),
            DataCell(Text(pct(f1))),
            DataCell(Text(support.toString())),
          ]);
        }).toList(),
      ),
    );
  }
}
