import 'package:flutter/material.dart';
import '../core/api_client.dart';

class GmailSettingsScreen extends StatefulWidget {
  const GmailSettingsScreen({super.key});

  @override
  State<GmailSettingsScreen> createState() => _GmailSettingsScreenState();
}

class _GmailSettingsScreenState extends State<GmailSettingsScreen> {
  final ApiClient _api = ApiClient();
  String? _statusText;
  String? _authUrl;
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final st = await _api.getGmailStatus();
      setState(() {
        if (st['connected'] == true) {
          _statusText = 'Connected: ${st['email'] ?? ''}';
        } else {
          _statusText = 'Not connected';
        }
      });
    } catch (e) {
      setState(() => _statusText = 'Error loading status');
    }
    setState(() => _loading = false);
  }

  Future<void> _getAuthUrl() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await _api.getGmailAuthorizeUrl();
      setState(() => _authUrl = resp['url'] as String?);
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _exchangeCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final resp = await _api.exchangeGmailCode(code);
      if (resp['status'] == 'ok') {
        if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Gmail connected')));
        _codeController.clear();
        await _loadStatus();
      } else {
        if (mounted) messenger.showSnackBar(SnackBar(content: Text('Exchange response: $resp')));
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error exchanging code: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final status = await _api.syncGmail();
      if (!mounted) return;
      if (status == 202) {
        messenger.showSnackBar(const SnackBar(content: Text('Gmail sync started')));
      } else {
        messenger.showSnackBar(SnackBar(content: Text('Sync returned: $status')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Sync error: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gmail Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Status: ${_statusText ?? "..."}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _getAuthUrl,
              icon: const Icon(Icons.login),
              label: const Text('Get Authorization URL'),
            ),
            if (_authUrl != null) ...[
              const SizedBox(height: 8),
              SelectableText(_authUrl!),
              const SizedBox(height: 8),
              const Text('After granting access, paste the returned code below:'),
              TextField(controller: _codeController, decoration: const InputDecoration(hintText: 'Authorization code')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _exchangeCode, child: const Text('Submit Code')),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _sync, icon: const Icon(Icons.sync), label: const Text('Sync Inbox')),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: _loadStatus, icon: const Icon(Icons.refresh), label: const Text('Refresh Status')),
            if (_loading) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
