import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  final Dio _dio;
  final StorageService _storage;

  ApiService(this._dio, this._storage) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to requests
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - refresh token
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.getRefreshToken();
            if (refreshToken != null) {
              try {
                final response = await _dio.post('/auth/refresh', data: {
                  'refreshToken': refreshToken,
                });
                
                final newToken = response.data['data']['token'];
                await _storage.saveToken(newToken);
                
                // Retry original request
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                return handler.resolve(await _dio.fetch(error.requestOptions));
              } catch (e) {
                // Refresh failed, logout
                await _storage.clearAuth();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Auth endpoints
  Future<Response> register(Map<String, dynamic> data) {
    return _dio.post('/auth/register', data: data);
  }

  Future<Response> login(Map<String, dynamic> data) {
    return _dio.post('/auth/login', data: data);
  }

  Future<Response> logout() {
    return _dio.post('/auth/logout');
  }

  // Session endpoints
  Future<Response> createSession(String language) {
    return _dio.post('/sessions/create', data: {'language': language});
  }

  Future<Response> joinSession(String sessionCode, String language) {
    return _dio.post('/sessions/join', data: {
      'sessionCode': sessionCode,
      'language': language,
    });
  }

  Future<Response> getSession(String sessionId) {
    return _dio.get('/sessions/$sessionId');
  }

  Future<Response> endSession(String sessionId) {
    return _dio.delete('/sessions/$sessionId');
  }

  Future<Response> getSessionHistory(String sessionId, {int limit = 50}) {
    return _dio.get('/sessions/$sessionId/history', queryParameters: {
      'limit': limit,
    });
  }

  // User endpoints
  Future<Response> getProfile() {
    return _dio.get('/users/profile');
  }

  Future<Response> updateProfile(Map<String, dynamic> data) {
    return _dio.put('/users/profile', data: data);
  }

  Future<Response> getUserStats() {
    return _dio.get('/users/stats');
  }

  // Translation endpoints
  Future<Response> getSupportedLanguages() {
    return _dio.get('/translations/languages');
  }

  Future<Response> getTranslationStats() {
    return _dio.get('/translations/stats');
  }
}
