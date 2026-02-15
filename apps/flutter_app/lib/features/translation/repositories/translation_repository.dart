import '../../../core/services/websocket_service.dart';

class TranslationRepository {
  final WebSocketService _wsService;

  TranslationRepository(this._wsService);

  Stream<Map<String, dynamic>> get transcriptionStream => _wsService.transcriptionStream;
  Stream<Map<String, dynamic>> get translationStream => _wsService.translationStream;
  Stream<Map<String, dynamic>> get processingStream => _wsService.processingStream;

  void sendAudioChunk(String audioData, int sequence) {
    // Session ID should be set when joining
    // This is a simplified version
    _wsService.sendAudioChunk('', audioData, sequence);
  }

  void sendText(String text, int sequence) {
    _wsService.sendText('', text, sequence);
  }
}
