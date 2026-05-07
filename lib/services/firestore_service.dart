// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/user_model.dart';
import '../models/pig_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════════
  // PIGS
  // ══════════════════════════════════════════════════════════════════════════

  static Stream<List<PigModel>> pigsStream(String userId) => _db
      .collection('pigs')
      .where('userId', isEqualTo: userId)
      .where('status', whereNotIn: ['sold', 'deceased'])
      .orderBy('status')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PigModel.fromDoc).toList());

  static Stream<List<PigModel>> allPigsStream(String userId) => _db
      .collection('pigs')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PigModel.fromDoc).toList());

  static Future<String> addPig(PigModel pig) async {
    final ref = await _db.collection('pigs').add(pig.toMap());
    return ref.id;
  }

  static Future<void> updatePig(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('pigs').doc(id).update(data);
  }

  static Future<void> deletePig(String id) =>
      _db.collection('pigs').doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // PER-PIG HEALTH  (pigs/{pigId}/health/)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<HealthRecord>> getPigHealth(String pigId) async {
    final snap = await _db
        .collection('pigs')
        .doc(pigId)
        .collection('health')
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(HealthRecord.fromDoc).toList();
  }

  static Future<void> addPigHealthRecord(
      String pigId, HealthRecord record) async {
    await _db
        .collection('pigs')
        .doc(pigId)
        .collection('health')
        .add(record.toMap());
  }

  static Future<void> deletePigHealthRecord(
      String pigId, String recordId) async {
    await _db
        .collection('pigs')
        .doc(pigId)
        .collection('health')
        .doc(recordId)
        .delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PER-PIG FEEDING  (pigs/{pigId}/feeding/)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<FeedRecord>> getPigFeeding(String pigId) async {
    final snap = await _db
        .collection('pigs')
        .doc(pigId)
        .collection('feeding')
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(FeedRecord.fromDoc).toList();
  }

  static Future<void> addPigFeedRecord(
      String pigId, FeedRecord record) async {
    await _db
        .collection('pigs')
        .doc(pigId)
        .collection('feeding')
        .add(record.toMap());
  }

  static Future<void> deletePigFeedRecord(
      String pigId, String recordId) async {
    await _db
        .collection('pigs')
        .doc(pigId)
        .collection('feeding')
        .doc(recordId)
        .delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PER-PIG WEIGHT  (pigs/{pigId}/weight/)
  // ══════════════════════════════════════════════════════════════════════════

  static Future<List<WeightRecord>> getPigWeightHistory(
      String pigId) async {
    final snap = await _db
        .collection('pigs')
        .doc(pigId)
        .collection('weight')
        .orderBy('date')
        .get();
    return snap.docs.map(WeightRecord.fromDoc).toList();
  }

  static Future<void> addPigWeightRecord(
      String pigId, double weightKg, {String? notes}) async {
    final now = DateTime.now();
    await _db
        .collection('pigs')
        .doc(pigId)
        .collection('weight')
        .add(WeightRecord(
      id:        '',
      pigId:     pigId,
      weightKg:  weightKg,
      notes:     notes,
      date:      now,
      createdAt: now,
    ).toMap());
    await updatePig(pigId, {'weight': weightKg});
  }

  static Future<void> deletePigWeightRecord(
      String pigId, String recordId) async {
    await _db
        .collection('pigs')
        .doc(pigId)
        .collection('weight')
        .doc(recordId)
        .delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GLOBAL FEEDING LOG  (Finance / Dashboard)
  // ══════════════════════════════════════════════════════════════════════════

  static Stream<List<FeedingRecord>> feedingStream(String userId) => _db
      .collection('feeding')
      .where('userId', isEqualTo: userId)
      .orderBy('feedTime', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(FeedingRecord.fromDoc).toList());

  static Future<void> addFeeding(FeedingRecord r) =>
      _db.collection('feeding').add(r.toMap());

  static Future<void> deleteFeeding(String id) =>
      _db.collection('feeding').doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // FINANCE / TRANSACTIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Stream<List<TransactionModel>> transactionsStream(
      String userId) =>
      _db
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(100)
          .snapshots()
          .map((s) => s.docs.map(TransactionModel.fromDoc).toList());

  static Future<void> addTransaction(TransactionModel t) =>
      _db.collection('transactions').add(t.toMap());

  static Future<void> deleteTransaction(String id) =>
      _db.collection('transactions').doc(id).delete();

  static Future<Map<String, double>> getFinancialSummary(
      String userId) async {
    final snapshot = await _db
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();
    double income = 0, expenses = 0;
    for (final doc in snapshot.docs) {
      final t = TransactionModel.fromDoc(doc);
      if (t.type == TransactionType.sale ||
          t.type == TransactionType.income) {
        income += t.amount;
      } else {
        expenses += t.amount;
      }
    }
    return {
      'income':   income,
      'expenses': expenses,
      'profit':   income - expenses,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMMUNITY POSTS
  // ══════════════════════════════════════════════════════════════════════════

  static Stream<List<CommunityPost>> postsStream({String? category}) {
    Query q = _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(30);
    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category.toLowerCase());
    }
    return q
        .snapshots()
        .map((s) => s.docs.map(CommunityPost.fromDoc).toList());
  }

  static Future<void> addPost(CommunityPost post) =>
      _db.collection('posts').add(post.toMap());

  static Future<void> toggleLike(String postId, String userId) async {
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final likes = List<String>.from(data['likes'] ?? []);
    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }
    await ref.update({'likes': likes});
  }

  static Future<void> deletePost(String id) =>
      _db.collection('posts').doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static Stream<List<Map<String, dynamic>>> notificationsStream(
      String userId) =>
      _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .map((s) =>
          s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  static Future<void> markNotificationRead(String id) => _db
      .collection('notifications')
      .doc(id)
      .update({'read': true});

  static Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) =>
      _db.collection('notifications').add({
        'userId':    userId,
        'title':     title,
        'message':   message,
        'type':      type,
        'read':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  // ══════════════════════════════════════════════════════════════════════════
  // USER
  // ══════════════════════════════════════════════════════════════════════════

  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) return UserModel.fromDoc(doc);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Stream<UserModel> userStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .where((doc) => doc.exists)
      .map((doc) => UserModel.fromDoc(doc));

  static Future<void> updateUser(
      String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ══════════════════════════════════════════════════════════════════════════
  // AI CHAT SESSIONS
  // Firestore path: users/{uid}/ai_chats/{sessionId}/messages/{msgId}
  // ══════════════════════════════════════════════════════════════════════════

  /// Creates a new AI chat session and returns its generated ID.
  static Future<String> createAiChatSession(
      String userId, String firstMessage) async {
    final title = firstMessage.length > 60
        ? '${firstMessage.substring(0, 60)}...'
        : firstMessage;

    final ref = await _db
        .collection('users')
        .doc(userId)
        .collection('ai_chats')
        .add({
      'title':        title,
      'messageCount': 0,
      'createdAt':    FieldValue.serverTimestamp(),
      'updatedAt':    FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Saves a single message (user or assistant) to an AI chat session.
  static Future<void> saveAiMessage({
    required String userId,
    required String sessionId,
    required String role,    // 'user' or 'assistant'
    required String content,
  }) async {
    try {
      final sessionRef = _db
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .doc(sessionId);

      await sessionRef.collection('messages').add({
        'role':      role,
        'content':   content,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await sessionRef.update({
        'messageCount': FieldValue.increment(1),
        'updatedAt':    FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently ignore — chat still works even if storage fails
    }
  }

  /// Streams all AI chat sessions for a user, newest first.
  static Stream<List<Map<String, dynamic>>> aiChatSessionsStream(
      String userId) =>
      _db
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) => s.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());

  /// Loads all messages from a specific AI chat session, in order.
  static Future<List<Map<String, dynamic>>> getAiChatMessages({
    required String userId,
    required String sessionId,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  /// Deletes an AI chat session and ALL its messages (batch delete).
  static Future<void> deleteAiChatSession(
      String userId, String sessionId) async {
    try {
      final messages = await _db
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .doc(sessionId)
          .collection('messages')
          .get();

      final batch = _db.batch();
      for (final msg in messages.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(
        _db
            .collection('users')
            .doc(userId)
            .collection('ai_chats')
            .doc(sessionId),
      );
      await batch.commit();
    } catch (_) {
      // Silently ignore
    }
  }
}