import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';
import '../models/session_model.dart';

class SessionRepository {
  final ApiService _apiService;
  final WebSocketService _wsService;

  SessionRepository(this._apiService, this._wsService);

  Future<SessionModel> createSession(String language) async {
    final response = await _apiService.createSession(language);
    return SessionModel.fromJson(response.data['data']);
  }

  Future<SessionModel> joinSession(String sessionCode, String language) async {
    final response = await _apiService.joinSession(sessionCode, language);
    return SessionModel.fromJson(response.data['data']);
  }

  Future<void> endSession(String sessionId) async {
    await _apiService.endSession(sessionId);
  }

  Future<SessionModel> getSession(String sessionId) async {
    final response = await _apiService.getSession(sessionId);
    return SessionModel.fromJson(response.data['data']);
  }
}
