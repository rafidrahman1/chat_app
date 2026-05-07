import 'package:cloud_firestore/cloud_firestore.dart';

class ValorantStackMember {
  final String uid;
  final String displayName;
  final DateTime joinedAt;

  const ValorantStackMember({required this.uid, required this.displayName, required this.joinedAt});

  factory ValorantStackMember.fromMap(Map<String, dynamic> map) {
    final joinedAtValue = map['joinedAt'];
    final joinedAt = switch (joinedAtValue) {
      Timestamp timestamp => timestamp.toDate(),
      DateTime dateTime => dateTime,
      String raw => DateTime.tryParse(raw) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    return ValorantStackMember(uid: '${map['uid'] ?? ''}'.trim(), displayName: '${map['displayName'] ?? ''}'.trim(), joinedAt: joinedAt);
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'displayName': displayName, 'joinedAt': Timestamp.fromDate(joinedAt)};
  }
}

class ValorantStackState {
  final String sessionKey;
  final List<ValorantStackMember> members;

  const ValorantStackState({required this.sessionKey, required this.members});

  factory ValorantStackState.empty(String sessionKey) {
    return ValorantStackState(sessionKey: sessionKey, members: const []);
  }

  int get count => members.length;

  bool get isFull => count >= 5;

  bool containsUser(String uid) => members.any((member) => member.uid == uid);

  factory ValorantStackState.fromMap(Map<String, dynamic>? map, String activeSessionKey) {
    if (map == null) {
      return ValorantStackState.empty(activeSessionKey);
    }

    final storedSessionKey = '${map['sessionKey'] ?? ''}'.trim();
    if (storedSessionKey != activeSessionKey) {
      return ValorantStackState.empty(activeSessionKey);
    }

    final rawMembers = map['members'];
    final members = <ValorantStackMember>[];
    if (rawMembers is Iterable) {
      for (final item in rawMembers) {
        if (item is Map<String, dynamic>) {
          members.add(ValorantStackMember.fromMap(item));
        } else if (item is Map) {
          members.add(ValorantStackMember.fromMap(item.cast<String, dynamic>()));
        }
      }
    }

    return ValorantStackState(sessionKey: activeSessionKey, members: members.take(5).toList());
  }

  Map<String, dynamic> toMap() {
    return {'sessionKey': sessionKey, 'members': members.map((member) => member.toMap()).toList()};
  }
}

enum ValorantStackJoinResult { joined, alreadyJoined, full, unauthenticated }
