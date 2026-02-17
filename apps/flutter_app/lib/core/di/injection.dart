import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/session/providers/session_provider.dart';
import '../../features/session/repositories/session_repository.dart';
import '../../features/translation/providers/translation_provider.dart';
import '../../features/translation/repositories/translation_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // Get environment variables with fallbacks
  final apiBaseUrl = dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000/api/v1');
  final wsUrl = dotenv.get('WS_URL', fallback: 'ws://localhost:3001');
  
  // Dio
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  getIt.registerSingleton<Dio>(dio);
  
  // Core Services
  getIt.registerLazySingleton<StorageService>(
    () => StorageService(getIt<SharedPreferences>()),
  );
  
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(getIt<Dio>(), getIt<StorageService>()),
  );
  
  getIt.registerLazySingleton<WebSocketService>(
    () => WebSocketService(
      wsUrl: wsUrl,
      storageService: getIt<StorageService>(),
    ),
  );
  
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<ApiService>(), getIt<StorageService>()),
  );
  
  getIt.registerLazySingleton<SessionRepository>(
    () => SessionRepository(getIt<ApiService>(), getIt<WebSocketService>()),
  );
  
  getIt.registerLazySingleton<TranslationRepository>(
    () => TranslationRepository(getIt<WebSocketService>()),
  );
  
  // Providers
  getIt.registerFactory<AuthProvider>(
    () => AuthProvider(getIt<AuthRepository>()),
  );
  
  getIt.registerFactory<SessionProvider>(
    () => SessionProvider(getIt<SessionRepository>()),
  );
  
  getIt.registerFactory<TranslationProvider>(
    () => TranslationProvider(
      getIt<TranslationRepository>(),
      getIt<AudioService>(),
    ),
  );
}
