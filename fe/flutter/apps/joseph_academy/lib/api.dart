import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class JosephAcademyApiClient {
  JosephAcademyApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'JOSEPH_ACADEMY_API_BASE_URL',
            defaultValue: 'http://127.0.0.1:8787',
          );

  final http.Client _client;
  final String baseUrl;

  Future<DashboardPayload> fetchDashboard() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/dashboard'));
    return DashboardPayload.fromJson(_decode(response));
  }

  Future<CatalogPayload> fetchCatalog() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/catalog'));
    return CatalogPayload.fromJson(_decode(response));
  }

  Future<LearnerDetailPayload> fetchLearnerDetail(String learnerId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/learners/$learnerId'),
    );
    return LearnerDetailPayload.fromJson(_decode(response));
  }

  Future<void> assignPlan({
    required String learnerId,
    required String planTemplateId,
    required String startDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/plan-assignments'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'learner_id': learnerId,
        'plan_template_id': planTemplateId,
        'start_date': startDate,
      }),
    );
    _decode(response);
  }

  Future<void> recordSession({
    required String sessionId,
    required double score,
    required double maxScore,
    required int durationMinutes,
    required String notes,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/sessions/$sessionId/record'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'score': score,
        'max_score': maxScore,
        'duration_minutes': durationMinutes,
        'notes': notes,
      }),
    );
    _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request failed');
    }
    return decoded;
  }
}
