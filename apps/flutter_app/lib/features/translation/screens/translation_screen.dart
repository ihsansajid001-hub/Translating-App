import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/translation_provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/di/injection.dart';

class TranslationScreen extends StatefulWidget {
  final String sessionId;
  final String sessionCode;
  final String language;

  const TranslationScreen({
    super.key,
    required this.sessionId,
    required this.sessionCode,
    required this.language,
  });

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  late WebSocketService _wsService;
  bool _showCode = true;

  @override
  void initState() {
    super.initState();
    _wsService = getIt<WebSocketService>();
    _connectToSession();
  }

  Future<void> _connectToSession() async {
    await _wsService.connect();
    _wsService.joinSession(widget.sessionId);

    // Listen to partner connection
    _wsService.partnerConnectedStream.listen((_) {
      context.read<TranslationProvider>().setPartnerConnected(true);
      setState(() {
        _showCode = false;
      });
    });

    _wsService.partnerDisconnectedStream.listen((_) {
      context.read<TranslationProvider>().setPartnerConnected(false);
    });
  }

  @override
  void dispose() {
    _wsService.leaveSession(widget.sessionId);
    super.dispose();
  }

  void _copySessionCode() {
    Clipboard.setData(ClipboardData(text: widget.sessionCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session code copied!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              setState(() {
                _showCode = !_showCode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Session Code Banner
          if (_showCode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Column(
                children: [
                  Text(
                    'Session Code',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.sessionCode,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copySessionCode,
                      ),
                    ],
                  ),
                  Consumer<TranslationProvider>(
                    builder: (context, provider, child) {
                      return Text(
                        provider.partnerConnected
                            ? '✅ Partner Connected'
                            : '⏳ Waiting for partner...',
                        style: TextStyle(
                          color: provider.partnerConnected ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Messages List
          Expanded(
            child: Consumer<TranslationProvider>(
              builder: (context, provider, child) {
                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Press and hold to speak',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return _MessageBubble(
                      message: message,
                      isFromMe: message.isFromMe,
                    );
                  },
                );
              },
            ),
          ),

          // Latency Stats
          Consumer<TranslationProvider>(
            builder: (context, provider, child) {
              if (provider.latencyStats == null) return const SizedBox.shrink();

              final stats = provider.latencyStats!;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LatencyStat(
                      label: 'STT',
                      value: '${stats['stt']}ms',
                    ),
                    _LatencyStat(
                      label: 'Translation',
                      value: '${stats['translation']}ms',
                    ),
                    _LatencyStat(
                      label: 'TTS',
                      value: '${stats['tts']}ms',
                    ),
                    _LatencyStat(
                      label: 'Total',
                      value: '${stats['total']}ms',
                      isTotal: true,
                    ),
                  ],
                ),
              );
            },
          ),

          // Recording Button
          Container(
            padding: const EdgeInsets.all(24),
            child: Consumer<TranslationProvider>(
              builder: (context, provider, child) {
                return GestureDetector(
                  onLongPressStart: (_) {
                    if (provider.partnerConnected) {
                      provider.startRecording();
                    }
                  },
                  onLongPressEnd: (_) {
                    provider.stopRecording();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: provider.isRecording ? 100 : 80,
                    height: provider.isRecording ? 100 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.isRecording
                          ? Colors.red
                          : (provider.partnerConnected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey),
                      boxShadow: provider.isRecording
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      provider.isRecording ? Icons.mic : Icons.mic_none,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          // Processing Indicator
          Consumer<TranslationProvider>(
            builder: (context, provider, child) {
              if (!provider.isProcessing) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Processing...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isFromMe;

  const _MessageBubble({
    required this.message,
    required this.isFromMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromMe
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFromMe && message.originalText.isNotEmpty)
              Text(
                message.originalText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (!isFromMe && message.originalText.isNotEmpty)
              const SizedBox(height: 4),
            Text(
              isFromMe ? message.originalText : message.translatedText,
              style: TextStyle(
                color: isFromMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (message.latency != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${message.latency}ms',
                  style: TextStyle(
                    color: isFromMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LatencyStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _LatencyStat({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Theme.of(context).colorScheme.primary : Colors.black87,
          ),
        ),
      ],
    );
  }
}
