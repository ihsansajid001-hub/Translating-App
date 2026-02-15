import 'package:flutter/foundation.dart';
import '../repositories/translation_repository.dart';
import '../../../core/services/audio_service.dart';
import '../models/translation_message.dart';

class TranslationProvider with ChangeNotifier {
  final TranslationRepository _repository;
  final AudioService _audioService;
  
  final List<TranslationMessage> _messages = [];
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _partnerConnected = false;
  int _sequence = 0;
  Map<String, dynamic>? _latencyStats;

  List<TranslationMessage> get messages => List.unmodifiable(_messages);
  bool get isRecording => _isRecording;
  bool get isProcessing => _isProcessing;
  bool get partnerConnected => _partnerConnected;
  Map<String, dynamic>? get latencyStats => _latencyStats;

  TranslationProvider(this._repository, this._audioService) {
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to audio chunks
    _audioService.audioChunkStream.listen((audioData) {
      if (_isRecording) {
        _repository.sendAudioChunk(audioData, _sequence++);
      }
    });

    // Listen to transcriptions
    _repository.transcriptionStream.listen((data) {
      _addMessage(TranslationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalText: data['text'],
        translatedText: '',
        isFromMe: true,
        timestamp: DateTime.now(),
        latency: data['latency'],
      ));
    });

    // Listen to translations
    _repository.translationStream.listen((data) async {
      _addMessage(TranslationMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalText: data['originalText'],
        translatedText: data['translatedText'],
        isFromMe: false,
        timestamp: DateTime.now(),
        latency: data['latency']?['total'],
      ));

      // Play audio
      if (data['audioData'] != null) {
        await _audioService.playAudio(data['audioData']);
      }

      _latencyStats = data['latency'];
      notifyListeners();
    });

    // Listen to processing status
    _repository.processingStream.listen((data) {
      _isProcessing = data['type'] == 'start';
      notifyListeners();
    });
  }

  Future<void> startRecording() async {
    final success = await _audioService.startRecording();
    if (success) {
      _isRecording = true;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    await _audioService.stopRecording();
    _isRecording = false;
    notifyListeners();
  }

  void _addMessage(TranslationMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void setPartnerConnected(bool connected) {
    _partnerConnected = connected;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
