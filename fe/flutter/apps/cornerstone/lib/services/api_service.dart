import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

class CornerstoneApiClient {
  CornerstoneApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? _resolveBaseUrl();

  final http.Client _client;
  final String baseUrl;
  String? _viewerUsername;

  void setViewerUsername(String? username) {
    final normalized = username?.trim();
    _viewerUsername =
        normalized == null || normalized.isEmpty ? null : normalized;
  }

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
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/dashboard'),
      headers: _viewerHeaders(),
    );
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
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/library'),
      headers: _viewerHeaders(),
    );
    return LibraryPayload.fromJson(_decode(response));
  }

  Future<LibraryDocumentsPayload> fetchLibraryDocuments() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/library/documents'),
      headers: _viewerHeaders(),
    );
    return LibraryDocumentsPayload.fromJson(_decode(response));
  }

  Future<LibraryDocumentData> fetchLibraryDocument(String routePath) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/library/document').replace(
        queryParameters: {'route_path': routePath},
      ),
      headers: _viewerHeaders(),
    );
    return LibraryDocumentPayload.fromJson(_decode(response)).document;
  }

  Future<LearnerDetailPayload> fetchLearnerDetail(String learnerId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/learners/$learnerId'),
      headers: _viewerHeaders(),
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
      headers: _viewerHeaders(contentTypeJson: true),
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
      headers: _viewerHeaders(contentTypeJson: true),
      body: jsonEncode({
        'score': score,
        'max_score': maxScore,
        'duration_minutes': durationMinutes,
        'notes': notes,
      }),
    );
    _decode(response);
  }

  Future<ActivityInstance> startSessionMaterialActivity({
    required String sessionId,
    required String sessionMaterialId,
  }) async {
    final response = await _client.post(
      Uri.parse(
        '$baseUrl/api/v1/sessions/$sessionId/materials/$sessionMaterialId/start',
      ),
      headers: _viewerHeaders(),
    );
    return ActivityStartPayload.fromJson(_decode(response)).activity;
  }

  Future<CompleteActivityResponse> completeActivity({
    required String activityInstanceId,
    required List<String> answers,
    required List<ActivityItem> items,
    required int durationSeconds,
    required String notes,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/activity-instances/$activityInstanceId/complete'),
      headers: _viewerHeaders(contentTypeJson: true),
      body: jsonEncode({
        'responses': List.generate(
          items.length,
          (index) => {
            'item_id': items[index].itemId,
            'value': answers[index],
          },
        ),
        'duration_seconds': durationSeconds,
        'notes': notes,
      }),
    );
    return CompleteActivityResponse.fromJson(_decode(response));
  }

  Map<String, String> _viewerHeaders({bool contentTypeJson = false}) {
    final headers = <String, String>{};
    if (contentTypeJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (_viewerUsername != null) {
      headers['x-cornerstone-viewer'] = _viewerUsername!;
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request failed');
    }
    return decoded;
  }
}
