import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Logger _logger = Logger();
  
  bool _isRecording = false;
  StreamSubscription? _recordingSubscription;
  
  final _audioChunkController = StreamController<String>.broadcast();
  Stream<String> get audioChunkStream => _audioChunkController.stream;

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> startRecording() async {
    if (_isRecording) return false;

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _logger.e('Microphone permission denied');
      return false;
    }

    try {
      if (await _recorder.hasPermission()) {
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
            bitRate: 128000,
          ),
        );

        _isRecording = true;
        
        // Process audio chunks
        _recordingSubscription = stream.listen((chunk) {
          // Convert to base64 and emit
          final base64Audio = base64Encode(chunk);
          _audioChunkController.add(base64Audio);
        });

        _logger.i('Recording started');
        return true;
      }
    } catch (e) {
      _logger.e('Failed to start recording: $e');
    }
    return false;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      await _recordingSubscription?.cancel();
      _isRecording = false;
      _logger.i('Recording stopped');
    } catch (e) {
      _logger.e('Failed to stop recording: $e');
    }
  }

  Future<void> playAudio(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      await _player.play(BytesSource(bytes));
    } catch (e) {
      _logger.e('Failed to play audio: $e');
    }
  }

  Future<void> stopPlaying() async {
    await _player.stop();
  }

  bool get isRecording => _isRecording;

  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _recordingSubscription?.cancel();
    _audioChunkController.close();
  }
}
