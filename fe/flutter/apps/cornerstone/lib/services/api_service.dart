import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class CornerstoneApiClient {
  CornerstoneApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String baseUrl;

  static String _resolveBaseUrl() {
    const configuredBaseUrl = String.fromEnvironment(
      'CORNERSTONE_API_BASE_URL',
      defaultValue: '',
    );
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    final runtimeBase = Uri.base;
    if (runtimeBase.scheme == 'http' || runtimeBase.scheme == 'https') {
      return runtimeBase.origin;
    }

    return 'http://localhost';
  }

  Future<DashboardPayload> fetchDashboard() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/dashboard'));
    return DashboardPayload.fromJson(_decode(response));
  }

  Future<ViewerSessionPayload> fetchViewerSession({String? username}) async {
    final trimmedUsername = username?.trim();
    final uri = Uri.parse('$baseUrl/api/v1/session').replace(
      queryParameters: trimmedUsername == null || trimmedUsername.isEmpty
          ? null
          : {'username': trimmedUsername},
    );
    final response = await _client.get(uri);
    return ViewerSessionPayload.fromJson(_decode(response));
  }

  Future<ViewerSessionPayload> login(String username) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/session'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    return ViewerSessionPayload.fromJson(_decode(response));
  }

  Future<void> logout() async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/v1/session'));
    _decode(response);
  }

  Future<LibraryPayload> fetchLibrary() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/library'));
    return LibraryPayload.fromJson(_decode(response));
  }

  Future<LearnerDetailPayload> fetchLearnerDetail(String learnerId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/learners/$learnerId'),
    );
    return LearnerDetailPayload.fromJson(_decode(response));
  }

  Future<void> createAssignment({
    required String learnerId,
    required String playlistId,
    required String startDate,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/assignments'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'learner_id': learnerId,
        'playlist_id': playlistId,
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
