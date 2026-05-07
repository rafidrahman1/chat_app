import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firestore_paths.dart';
import '../../model/valorant_stack_state.dart';

class ValorantStackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _stackDoc => _firestore.collection(FirestorePaths.valorantStacksCollection).doc(FirestorePaths.dailyValorantStackDoc);

  String activeSessionKey([DateTime? now]) => _dateKeyForResetTime(now ?? DateTime.now());

  DateTime nextResetTime([DateTime? now]) {
    final current = now ?? DateTime.now();
    final todayReset = DateTime(current.year, current.month, current.day, 23, 59);
    if (current.isBefore(todayReset)) {
      return todayReset;
    }
    return todayReset.add(const Duration(days: 1));
  }

  Stream<ValorantStackState> watchStackState() {
    final controller = StreamController<ValorantStackState>();
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subscription;
    Timer? timer;
    Map<String, dynamic>? lastData;

    void emitCurrentState() {
      if (controller.isClosed) return;
      controller.add(ValorantStackState.fromMap(lastData, activeSessionKey()));
    }

    void scheduleResetTick() {
      timer?.cancel();
      final delay = nextResetTime().difference(DateTime.now());
      timer = Timer(delay.isNegative ? Duration.zero : delay, () async {
        final currentKey = activeSessionKey();
        final staleSessionKey = '${lastData?['sessionKey'] ?? ''}'.trim();

        if (lastData != null && staleSessionKey != currentKey) {
          await _stackDoc.set({'sessionKey': currentKey, 'members': const [], 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        }

        emitCurrentState();
        scheduleResetTick();
      });
    }

    controller.onListen = () {
      emitCurrentState();
      scheduleResetTick();
      subscription = _stackDoc.snapshots().listen((snapshot) {
        lastData = snapshot.data();
        emitCurrentState();
        scheduleResetTick();
      }, onError: controller.addError);
    };

    controller.onCancel = () async {
      timer?.cancel();
      await subscription?.cancel();
    };

    return controller.stream;
  }

  Future<ValorantStackJoinResult> joinStack({required String uid, required String displayName}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return ValorantStackJoinResult.unauthenticated;
    }

    final normalizedUid = uid.trim();
    final normalizedName = displayName.trim().isEmpty ? 'Unknown player' : displayName.trim();
    final sessionKey = activeSessionKey();

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_stackDoc);
      final state = ValorantStackState.fromMap(snapshot.data(), sessionKey);

      if (state.containsUser(normalizedUid)) {
        return ValorantStackJoinResult.alreadyJoined;
      }
      if (state.isFull) {
        return ValorantStackJoinResult.full;
      }

      final updatedMembers = [...state.members, ValorantStackMember(uid: normalizedUid, displayName: normalizedName, joinedAt: DateTime.now())];

      transaction.set(_stackDoc, {
        'sessionKey': sessionKey,
        'members': updatedMembers.map((member) => member.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return ValorantStackJoinResult.joined;
    });
  }

  String _dateKeyForResetTime(DateTime now) {
    final resetTime = DateTime(now.year, now.month, now.day, 23, 59);
    final sessionDate = now.isBefore(resetTime) ? now : now.add(const Duration(days: 1));
    final localDate = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    return _formatDate(localDate);
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }
}
