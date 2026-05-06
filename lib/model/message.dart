class Message {
  final int msgId;
  final String content;
  final DateTime timestamp;
  final String senderId;
  final String displayName;

  Message({required this.msgId, required this.content, required this.timestamp, required this.senderId, this.displayName = ''});

  //convert to a map
  Map<String, dynamic> toMap() {
    return {'content': content, 'timestamp': timestamp.toIso8601String(), 'senderId': senderId, 'msgId': msgId, 'displayName': displayName};
  }

  //create Message from a map (used when reading from Firestore)
  factory Message.fromMap(Map<String, dynamic> map) {
    // timestamp might be stored as a String (ISO) or as a Firestore Timestamp
    DateTime parsedTimestamp;
    final ts = map['timestamp'];
    if (ts is String) {
      parsedTimestamp = DateTime.parse(ts);
    } else if (ts is DateTime) {
      parsedTimestamp = ts;
    } else if (ts is Map && ts['_seconds'] != null) {
      // legacy Firestore timestamp map (if it ever appears)
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch((ts['_seconds'] as int) * 1000);
    } else {
      // Firestore Timestamp
      try {
        parsedTimestamp = (ts as dynamic).toDate();
      } catch (_) {
        parsedTimestamp = DateTime.now();
      }
    }

    return Message(
      msgId: (map['msgId'] is int) ? map['msgId'] : int.tryParse('${map['msgId']}') ?? 0,
      content: map['content'] ?? '',
      timestamp: parsedTimestamp,
      senderId: map['senderId'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }
}
