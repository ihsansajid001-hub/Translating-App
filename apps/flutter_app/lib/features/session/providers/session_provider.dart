import 'package:flutter/foundation.dart';
import '../repositories/session_repository.dart';
import '../models/session_model.dart';

class SessionProvider with ChangeNotifier {
  final SessionRepository _repository;
  
  SessionModel? _currentSession;
  bool _isLoading = false;
  String? _error;
  bool _partnerConnected = false;

  SessionModel? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get partnerConnected => _partnerConnected;

  SessionProvider(this._repository);

  Future<SessionModel?> createSession(String language) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSession = await _repository.createSession(language);
      _isLoading = false;
      notifyListeners();
      return _currentSession;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<SessionModel?> joinSession(String sessionCode, String language) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSession = await _repository.joinSession(sessionCode, language);
      _isLoading = false;
      notifyListeners();
      return _currentSession;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> endSession() async {
    if (_currentSession == null) return;

    try {
      await _repository.endSession(_currentSession!.id);
      _currentSession = null;
      _partnerConnected = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setPartnerConnected(bool connected) {
    _partnerConnected = connected;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSession() {
    _currentSession = null;
    _partnerConnected = false;
    notifyListeners();
  }
}
