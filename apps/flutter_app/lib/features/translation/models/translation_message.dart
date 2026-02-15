class TranslationMessage {
  final String id;
  final String originalText;
  final String translatedText;
  final bool isFromMe;
  final DateTime timestamp;
  final int? latency;

  TranslationMessage({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.isFromMe,
    required this.timestamp,
    this.latency,
  });

  factory TranslationMessage.fromJson(Map<String, dynamic> json) {
    return TranslationMessage(
      id: json['id'],
      originalText: json['originalText'],
      translatedText: json['translatedText'],
      isFromMe: json['isFromMe'],
      timestamp: DateTime.parse(json['timestamp']),
      latency: json['latency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'isFromMe': isFromMe,
      'timestamp': timestamp.toIso8601String(),
      'latency': latency,
    };
  }
}
