import 'package:flutter/material.dart';
import '../core/app_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../widgets/app_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _debugInfo;
  bool _isLoadingDebug = false;

  @override
  void initState() {
    super.initState();
    AppState().addListener(_onAppStateChanged);
    _loadDebugInfo();
  }

  @override
  void dispose() {
    AppState().removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoadingDebug = true;
    });
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/debug/model'));
      if (response.statusCode == 200) {
        setState(() {
          _debugInfo = json.decode(response.body) as Map<String, dynamic>;
          _isLoadingDebug = false;
        });
      } else {
        setState(() {
          _isLoadingDebug = false;
        });
      }
    } catch (_) {
      setState(() {
        _isLoadingDebug = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClassifier = AppState().classifier;

    return Scaffold(
      appBar: const SmartInboxAppBar(title: 'Settings', isRoot: true),
      drawer: const SmartInboxDrawer(currentRoute: AppNavigation.settings),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Classifier Engine',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select which backend model to use for sorting and priority determination.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text(
                      'Rules-Based Classifier',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Uses deterministic keyword scans.'),
                    value: 'rules',
                    groupValue: activeClassifier,
                    activeColor: Colors.amber.shade800,
                    onChanged: (value) {
                      if (value != null) {
                        AppState().setClassifier(value);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    title: const Text(
                      'Machine Learning Classifier',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Uses the trained TF-IDF + Logistic Regression model.'),
                    value: 'ml',
                    groupValue: activeClassifier,
                    activeColor: Colors.amber.shade800,
                    onChanged: (value) {
                      if (value != null) {
                        AppState().setClassifier(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ML Model Diagnostics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoadingDebug
                    ? const Center(child: CircularProgressIndicator())
                    : _debugInfo == null
                        ? const Text('Could not load ML diagnostics. Is the backend server running?')
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  _debugInfo!['model_loaded'] == true
                                      ? const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                                            SizedBox(width: 4),
                                            Text('Model Loaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      : const Row(
                                          children: [
                                            Icon(Icons.warning, color: Colors.orange, size: 16),
                                            SizedBox(width: 4),
                                            Text('Not Loaded (Using Fallback)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: 'Classifier Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${_debugInfo!['classifier']}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: 'Scikit-Learn Version: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${_debugInfo!['sklearn_version']}'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    const TextSpan(text: 'Model File Path:\n', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '${_debugInfo!['model_path']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _loadDebugInfo,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Refresh Diagnostics'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      // Call retrain endpoint
                                      final messenger = ScaffoldMessenger.of(context);
                                      setState(() {
                                        _isLoadingDebug = true;
                                      });
                                      int statusCode = -1;
                                      String? error;
                                      try {
                                        final response = await http.post(Uri.parse('$backendBaseUrl/retrain'));
                                        statusCode = response.statusCode;
                                      } catch (e) {
                                        error = e.toString();
                                      }
                                      if (!mounted) return;
                                      if (error != null) {
                                        messenger.showSnackBar(SnackBar(content: Text('Retrain error: $error')));
                                      } else if (statusCode == 202) {
                                        messenger.showSnackBar(const SnackBar(content: Text('Retrain job started')));
                                      } else {
                                        messenger.showSnackBar(SnackBar(content: Text('Retrain failed: $statusCode')));
                                      }
                                      setState(() {
                                        _isLoadingDebug = false;
                                      });
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retrain Model'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
