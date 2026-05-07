class UserProfile {
  final String uid;
  final String displayName;
  final String photoUrl;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      displayName: '${map['displayName'] ?? ''}'.trim(),
      photoUrl: '${map['photoUrl'] ?? ''}'.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}

