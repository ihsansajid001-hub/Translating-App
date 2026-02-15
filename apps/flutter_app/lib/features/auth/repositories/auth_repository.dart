import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository(this._apiService, this._storageService);

  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.login({
      'email': email,
      'password': password,
    });

    final data = response.data['data'];
    await _storageService.saveToken(data['token']);
    await _storageService.saveRefreshToken(data['refreshToken']);
    
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> register(String email, String password, String username) async {
    final response = await _apiService.register({
      'email': email,
      'password': password,
      'username': username,
    });

    final data = response.data['data'];
    await _storageService.saveToken(data['token']);
    await _storageService.saveRefreshToken(data['refreshToken']);
    
    return UserModel.fromJson(data['user']);
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _storageService.clearAuth();
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _storageService.getToken();
    if (token == null) return null;

    try {
      final response = await _apiService.getProfile();
      return UserModel.fromJson(response.data['data']);
    } catch (e) {
      return null;
    }
  }
}
