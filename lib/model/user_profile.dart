class UserProfile {
  final String uid;
  final String displayName;
  final String photoUrl;
  final String nickname;
  final String favoriteAgent;
  final String role;
  final bool isOnline;
  final DateTime? lastSeenAt;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.nickname,
    required this.favoriteAgent,
    required this.role,
    required this.isOnline,
    required this.lastSeenAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return DateTime.tryParse(raw);
      try {
        return (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return UserProfile(
      uid: uid,
      displayName: '${map['displayName'] ?? ''}'.trim(),
      photoUrl: '${map['photoUrl'] ?? ''}'.trim(),
      nickname: '${map['nickname'] ?? ''}'.trim(),
      favoriteAgent: '${map['favoriteAgent'] ?? ''}'.trim(),
      role: '${map['role'] ?? ''}'.trim(),
      isOnline: map['isOnline'] == true,
      lastSeenAt: parseDate(map['lastSeenAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'nickname': nickname,
      'favoriteAgent': favoriteAgent,
      'role': role,
      'isOnline': isOnline,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }
}
