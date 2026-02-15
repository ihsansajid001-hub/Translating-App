import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import 'storage_service.dart';

class WebSocketService {
  final String wsUrl;
  final StorageService storageService;
  final Logger _logger = Logger();
  
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Stream controllers for events
  final _connectionController = StreamController<bool>.broadcast();
  final _sessionJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _partnerConnectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _partnerDisconnectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _transcriptionController = StreamController<Map<String, dynamic>>.broadcast();
  final _translationController = StreamController<Map<String, dynamic>>.broadcast();
  final _processingController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get sessionJoinedStream => _sessionJoinedController.stream;
  Stream<Map<String, dynamic>> get partnerConnectedStream => _partnerConnectedController.stream;
  Stream<Map<String, dynamic>> get partnerDisconnectedStream => _partnerDisconnectedController.stream;
  Stream<Map<String, dynamic>> get transcriptionStream => _transcriptionController.stream;
  Stream<Map<String, dynamic>> get translationStream => _translationController.stream;
  Stream<Map<String, dynamic>> get processingStream => _processingController.stream;
  Stream<String> get errorStream => _errorController.stream;

  WebSocketService({required this.wsUrl, required this.storageService});

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await storageService.getToken();
    if (token == null) {
      _logger.e('No auth token found');
      return;
    }

    _socket = IO.io(wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _setupEventHandlers();
    _socket!.connect();
  }

  void _setupEventHandlers() {
    _socket!.on('connect', (_) {
      _logger.i('WebSocket connected');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.on('disconnect', (_) {
      _logger.w('WebSocket disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('error', (data) {
      _logger.e('WebSocket error: $data');
      _errorController.add(data['message'] ?? 'Unknown error');
    });

    _socket!.on('session_joined', (data) {
      _logger.i('Session joined: $data');
      _sessionJoinedController.add(data);
    });

    _socket!.on('partner_connected', (data) {
      _logger.i('Partner connected: $data');
      _partnerConnectedController.add(data);
    });

    _socket!.on('partner_disconnected', (data) {
      _logger.i('Partner disconnected: $data');
      _partnerDisconnectedController.add(data);
    });

    _socket!.on('transcription', (data) {
      _transcriptionController.add(data);
    });

    _socket!.on('translation', (data) {
      _translationController.add(data);
    });

    _socket!.on('processing_start', (data) {
      _processingController.add({'type': 'start', ...data});
    });

    _socket!.on('processing_end', (data) {
      _processingController.add({'type': 'end', ...data});
    });
  }

  void joinSession(String sessionId) {
    if (!_isConnected) {
      _logger.e('Not connected to WebSocket');
      return;
    }
    _socket!.emit('join_session', {'sessionId': sessionId});
  }

  void leaveSession(String sessionId) {
    if (!_isConnected) return;
    _socket!.emit('leave_session', {'sessionId': sessionId});
  }

  void sendAudioChunk(String sessionId, String audioData, int sequence) {
    if (!_isConnected) return;
    _socket!.emit('audio_chunk', {
      'sessionId': sessionId,
      'audioData': audioData,
      'sequence': sequence,
    });
  }

  void sendText(String sessionId, String text, int sequence) {
    if (!_isConnected) return;
    _socket!.emit('translate_text', {
      'sessionId': sessionId,
      'text': text,
      'sequence': sequence,
    });
  }

  void getHistory(String sessionId, {int limit = 20}) {
    if (!_isConnected) return;
    _socket!.emit('get_history', {
      'sessionId': sessionId,
      'limit': limit,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _sessionJoinedController.close();
    _partnerConnectedController.close();
    _partnerDisconnectedController.close();
    _transcriptionController.close();
    _translationController.close();
    _processingController.close();
    _errorController.close();
  }

  bool get isConnected => _isConnected;
}
