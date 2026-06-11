import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/email.dart';
import '../models/stats.dart';

class ApiClient {
  Future<List<Email>> fetchEmails({
    String? category,
    String? search,
    required String classifier,
    int limit = 100,
    int offset = 0,
  }) async {
    final Map<String, String> queryParams = {
      'classifier': classifier,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (category != null && category != 'All') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('$backendBaseUrl/emails').replace(queryParameters: queryParams);
    
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final List<dynamic> items = data['items'] as List<dynamic>? ?? [];
      return items.map((item) => Email.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load emails: ${response.statusCode}');
    }
  }

  Future<Email> fetchEmailDetails(int id) async {
    final uri = Uri.parse('$backendBaseUrl/emails/$id');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return Email.fromJson(data);
    } else {
      throw Exception('Failed to load email details: ${response.statusCode}');
    }
  }

  Future<EmailStats> fetchStats({String? search}) async {
    final Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    final uri = Uri.parse('$backendBaseUrl/stats').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return EmailStats.fromJson(data);
    } else {
      throw Exception('Failed to load stats: ${response.statusCode}');
    }
  }
}
