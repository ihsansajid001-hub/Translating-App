class SessionModel {
  final String id;
  final String sessionCode;
  final String? wsUrl;
  final String? partnerId;

  SessionModel({
    required this.id,
    required this.sessionCode,
    this.wsUrl,
    this.partnerId,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['sessionId'],
      sessionCode: json['sessionCode'],
      wsUrl: json['wsUrl'],
      partnerId: json['partnerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': id,
      'sessionCode': sessionCode,
      'wsUrl': wsUrl,
      'partnerId': partnerId,
    };
  }
}
