class Message {
  final String docId;
  final int msgId;
  final String content;
  final DateTime timestamp;
  final String senderId;
  final String type;
  final String? pollQuestion;
  final Map<String, int> pollVotes;
  final Map<String, String> pollVotesByUser;
  final Map<String, String> reactionsByUser;

  Message({
    required this.docId,
    required this.msgId,
    required this.content,
    required this.timestamp,
    required this.senderId,
    this.type = 'text',
    this.pollQuestion,
    this.pollVotes = const {},
    this.pollVotesByUser = const {},
    this.reactionsByUser = const {},
  });

  //convert to a map
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
      'msgId': msgId,
      'type': type,
      if (pollQuestion != null) 'pollQuestion': pollQuestion,
      'pollVotes': pollVotes,
      'pollVotesByUser': pollVotesByUser,
      'reactionsByUser': reactionsByUser,
    };
  }

  //create Message from a map (used when reading from Firestore)
  factory Message.fromMap(Map<String, dynamic> map, {required String docId}) {
    // timestamp might be stored as a String (ISO) or as a Firestore Timestamp
    DateTime parsedTimestamp;
    final ts = map['timestamp'];
    if (ts is String) {
      parsedTimestamp = DateTime.parse(ts);
    } else if (ts is DateTime) {
      parsedTimestamp = ts;
    } else if (ts is Map && ts['_seconds'] != null) {
      // legacy Firestore timestamp map (if it ever appears)
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
        (ts['_seconds'] as int) * 1000,
      );
    } else {
      // Firestore Timestamp
      try {
        parsedTimestamp = (ts as dynamic).toDate();
      } catch (_) {
        parsedTimestamp = DateTime.now();
      }
    }

    return Message(
      docId: docId,
      msgId: (map['msgId'] is int)
          ? map['msgId']
          : int.tryParse('${map['msgId']}') ?? 0,
      content: map['content'] ?? '',
      timestamp: parsedTimestamp,
      senderId: map['senderId'] ?? '',
      type: '${map['type'] ?? 'text'}',
      pollQuestion: map['pollQuestion'] == null
          ? null
          : '${map['pollQuestion']}'.trim(),
      pollVotes: (map['pollVotes'] as Map<String, dynamic>? ?? const {}).map(
        (key, value) => MapEntry('$key', (value as num?)?.toInt() ?? 0),
      ),
      pollVotesByUser:
          (map['pollVotesByUser'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry('$key', '$value'),
          ),
      reactionsByUser:
          (map['reactionsByUser'] as Map<String, dynamic>? ?? const {}).map(
            (key, value) => MapEntry('$key', '$value'),
          ),
    );
  }
}
