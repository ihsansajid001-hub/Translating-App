import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/session/screens/create_session_screen.dart';
import '../../features/session/screens/join_session_screen.dart';
import '../../features/translation/screens/translation_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/history/screens/history_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createSession = '/create-session';
  static const String joinSession = '/join-session';
  static const String translation = '/translation';
  static const String profile = '/profile';
  static const String history = '/history';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      
      case createSession:
        return MaterialPageRoute(builder: (_) => const CreateSessionScreen());
      
      case joinSession:
        return MaterialPageRoute(builder: (_) => const JoinSessionScreen());
      
      case translation:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => TranslationScreen(
            sessionId: args['sessionId'],
            sessionCode: args['sessionCode'],
            language: args['language'],
          ),
        );
      
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case history:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => HistoryScreen(sessionId: args?['sessionId']),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
