// lib/providers/providers.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pig_model.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PIG PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class PigProvider extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<PigModel> _pigs   = [];
  bool    _loading       = false;
  String? _error;

  List<PigModel> get pigs         => List.unmodifiable(_pigs);
  bool    get loading             => _loading;
  String? get error               => _error;

  List<PigModel> get activePigs   => _pigs.where((p) => p.isActive).toList();
  List<PigModel> get soldPigs     => _pigs.where((p) => p.status == PigStatus.sold).toList();
  List<PigModel> get allPigs      => List.unmodifiable(_pigs);
  int get totalPigs               => activePigs.length;
  int get healthyCount            => _pigs.where((p) => p.status == PigStatus.healthy).length;
  int get sickCount               => _pigs.where((p) => p.status == PigStatus.sick).length;
  int get quarantineCount         => _pigs.where((p) => p.status == PigStatus.quarantine).length;
  int get soldCount               => _pigs.where((p) => p.status == PigStatus.sold).length;

  List<HealthRecord> get health  => [];
  List<FeedRecord>   get feeding => [];

  List<PigModel> getAlerts() => _pigs
      .where((p) => p.status == PigStatus.sick || p.status == PigStatus.quarantine)
      .toList();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _pigsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('pigs');
  }

  StreamSubscription? _pigSub;

  void init() {
    _pigSub?.cancel();
    final ref = _pigsRef;
    if (ref == null) return;
    // ✅ Clear data immediately so previous user's data isn't shown
    _pigs = [];
    notifyListeners();

    _pigSub = ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
        _pigs = snap.docs.map(PigModel.fromDoc).toList();
        if (_loading) _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ✅ Called on logout — clears all pig data immediately
  void reset() {
    _pigSub?.cancel();
    _pigSub  = null;
    _pigs    = [];
    _loading = false;
    _error   = null;
    notifyListeners();
  }

  @override
  void dispose() { _pigSub?.cancel(); super.dispose(); }

  // ── PIG CRUD ──────────────────────────────────────────────────────────────

  Future<String?> addPig(PigModel pig) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return null;
      final doc = await ref.add(pig.toMap()..['userId'] = _uid);
      return doc.id;
    } catch (e) { _error = e.toString(); notifyListeners(); return null; }
  }

  Future<bool> updatePig(PigModel pig) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pig.id).update(pig.toMap()..['updatedAt'] = Timestamp.fromDate(DateTime.now()));
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> updatePigFields(String pigId, Map<String, dynamic> data) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await ref.doc(pigId).update(data);
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> updatePigStatus(String pigId, PigStatus status) =>
      updatePigFields(pigId, {'status': status.name});

  Future<bool> updatePigWeight(String pigId, double weight) =>
      updatePigFields(pigId, {'weight': weight});

  Future<bool> deletePig(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).delete();
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> deleteAllSold() async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final sold = _pigs.where((p) => p.status == PigStatus.sold).toList();
      final batch = _db.batch();
      for (final pig in sold) { batch.delete(ref.doc(pig.id)); }
      await batch.commit();
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  // ── HEALTH ────────────────────────────────────────────────────────────────

  Future<List<HealthRecord>> getPigHealth(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return [];
      final snap = await ref.doc(pigId).collection('health').orderBy('date', descending: true).get();
      return snap.docs.map(HealthRecord.fromDoc).toList();
    } catch (_) { return []; }
  }

  Future<bool> addHealthRecord(String pigId, HealthRecord record) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('health').add(record.toMap()..['userId'] = _uid);
      if (record.status == 'critical') {
        await updatePigStatus(pigId, PigStatus.quarantine);
      } else if (record.status == 'ongoing' || record.type == 'Treatment') {
        await updatePigStatus(pigId, PigStatus.sick);
      } else if (record.status == 'recovered') {
        await updatePigStatus(pigId, PigStatus.healthy);
      }
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> deleteHealthRecord(String pigId, String recordId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('health').doc(recordId).delete();
      return true;
    } catch (_) { return false; }
  }

  // ── FEEDING ───────────────────────────────────────────────────────────────

  Future<List<FeedRecord>> getPigFeeding(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return [];
      final snap = await ref.doc(pigId).collection('feeding').orderBy('date', descending: true).get();
      return snap.docs.map(FeedRecord.fromDoc).toList();
    } catch (_) { return []; }
  }

  Future<bool> addFeedRecord(String pigId, FeedRecord record) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('feeding').add(record.toMap()..['userId'] = _uid);
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> deleteFeedRecord(String pigId, String recordId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('feeding').doc(recordId).delete();
      return true;
    } catch (_) { return false; }
  }

  // ── WEIGHT ────────────────────────────────────────────────────────────────

  Future<List<WeightRecord>> getPigWeightHistory(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return [];
      final snap = await ref.doc(pigId).collection('weight').orderBy('date').get();
      return snap.docs.map(WeightRecord.fromDoc).toList();
    } catch (_) { return []; }
  }

  Future<bool> addWeightRecord(String pigId, double weightKg, {String? notes}) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final now = DateTime.now();
      await ref.doc(pigId).collection('weight').add(WeightRecord(
        id: '', pigId: pigId, weightKg: weightKg,
        notes: notes, date: now, createdAt: now,
      ).toMap());
      await updatePigWeight(pigId, weightKg);
      return true;
    } catch (e) { _error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> deleteWeightRecord(String pigId, String recordId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('weight').doc(recordId).delete();
      return true;
    } catch (_) { return false; }
  }

  void clearError() { _error = null; notifyListeners(); }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FINANCE PROVIDER
//  ✅ CRITICAL FIX: Each user sees ONLY their own transactions.
//     init() immediately clears old data so switching accounts
//     never shows the previous user's finance data.
// ─────────────────────────────────────────────────────────────────────────────

class FinanceProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  StreamSubscription<List<TransactionModel>>? _sub;
  String? _currentUserId; // Track who we're subscribed for
  double _totalIncome = 0, _totalExpenses = 0;

  List<TransactionModel> get transactions => _transactions;
  double get totalIncome   => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get profit        => _totalIncome - _totalExpenses;

  List<TransactionModel> get thisMonthTransactions {
    final now = DateTime.now();
    return _transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
  }

  double get monthlyIncome   => thisMonthTransactions.where((t) => t.type != TransactionType.expense).fold(0, (s, t) => s + t.amount);
  double get monthlyExpenses => thisMonthTransactions.where((t) => t.type == TransactionType.expense).fold(0, (s, t) => s + t.amount);

  void init(String userId) {
    // ✅ If already subscribed for this user, don't restart
    if (_currentUserId == userId && _sub != null) return;

    _sub?.cancel();
    _currentUserId = userId;

    // ✅ IMMEDIATELY clear previous user's data before new stream arrives
    _transactions  = [];
    _totalIncome   = 0;
    _totalExpenses = 0;
    notifyListeners(); // Update UI right away — no stale data shown

    _sub = FirestoreService.transactionsStream(userId).listen(
          (tx) {
        // ✅ Double-check the userId hasn't changed while stream was loading
        if (_currentUserId != userId) return;
        _transactions  = tx..sort((a, b) => b.date.compareTo(a.date));
        _totalIncome   = tx.where((t) => t.type != TransactionType.expense).fold(0, (s, t) => s + t.amount);
        _totalExpenses = tx.where((t) => t.type == TransactionType.expense).fold(0, (s, t) => s + t.amount);
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// ✅ Force re-subscribe even if already subscribed for this user.
  /// Call this after saving a transaction or when the screen mounts.
  void forceInit(String userId) {
    _sub?.cancel();
    _currentUserId = userId;
    _transactions  = [];
    _totalIncome   = 0;
    _totalExpenses = 0;
    notifyListeners();

    _sub = FirestoreService.transactionsStream(userId).listen(
          (tx) {
        if (_currentUserId != userId) return;
        _transactions  = tx..sort((a, b) => b.date.compareTo(a.date));
        _totalIncome   = tx.where((t) => t.type != TransactionType.expense).fold(0, (s, t) => s + t.amount);
        _totalExpenses = tx.where((t) => t.type == TransactionType.expense).fold(0, (s, t) => s + t.amount);
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  // ✅ Called on logout — wipes all finance data immediately
  void reset() {
    _sub?.cancel();
    _sub           = null;
    _currentUserId = null;
    _transactions  = [];
    _totalIncome   = 0;
    _totalExpenses = 0;
    notifyListeners();
  }

  Future<bool> addTransaction(TransactionModel t) async {
    try { await FirestoreService.addTransaction(t); return true; }
    catch (_) { return false; }
  }

  Future<bool> deleteTransaction(String id) async {
    try { await FirestoreService.deleteTransaction(id); return true; }
    catch (_) { return false; }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMMUNITY PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class CommunityProvider extends ChangeNotifier {
  List<CommunityPost> _posts = [];
  StreamSubscription<List<CommunityPost>>? _sub;
  String _activeCategory = 'All';

  List<CommunityPost> get posts          => _posts;
  String              get activeCategory => _activeCategory;

  void init({String? category}) {
    _activeCategory = category ?? 'All';
    _sub?.cancel();
    _sub = FirestoreService.postsStream(category: _activeCategory == 'All' ? null : _activeCategory)
        .listen((p) { _posts = p; notifyListeners(); }, onError: (_) {});
  }

  void reset() {
    _sub?.cancel(); _sub = null; _posts = []; notifyListeners();
  }

  void setCategory(String cat) {
    if (_activeCategory == cat) return;
    _activeCategory = cat;
    init(category: cat);
  }

  Future<bool> addPost(CommunityPost post) async {
    try { await FirestoreService.addPost(post); return true; }
    catch (_) { return false; }
  }

  Future<void> toggleLike(String postId, String userId) => FirestoreService.toggleLike(postId, userId);

  Future<bool> deletePost(String id) async {
    try { await FirestoreService.deletePost(id); return true; }
    catch (_) { return false; }
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORUM PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class ForumProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  List<ForumPost> _countyPosts  = [];
  List<ForumPost> _generalPosts = [];
  bool _loadingCounty  = false;
  bool _loadingGeneral = false;
  String _userCounty   = '';

  List<ForumPost> get countyPosts   => List.unmodifiable(_countyPosts);
  List<ForumPost> get generalPosts  => List.unmodifiable(_generalPosts);
  bool get loadingCounty            => _loadingCounty;
  bool get loadingGeneral           => _loadingGeneral;
  String get userCounty             => _userCounty;

  StreamSubscription? _countySub, _generalSub;

  void init(String county) { _userCounty = county; _subscribeCounty(county); _subscribeGeneral(); }

  void reset() {
    _countySub?.cancel(); _generalSub?.cancel();
    _countySub = null; _generalSub = null;
    _countyPosts = []; _generalPosts = [];
    _userCounty = ''; notifyListeners();
  }

  void _subscribeCounty(String county) {
    _countySub?.cancel();
    if (county.isEmpty) { _loadingCounty = false; notifyListeners(); return; }
    _loadingCounty = true; notifyListeners();
    _countySub = _db.collection('forum_posts').where('county', isEqualTo: county).snapshots().listen(
          (snap) {
        _countyPosts = snap.docs.map(ForumPost.fromDoc).toList().where((p) => !p.isNational).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loadingCounty = false; notifyListeners();
      },
      onError: (e) { debugPrint('ForumProvider county error: $e'); _loadingCounty = false; notifyListeners(); },
    );
  }

  void _subscribeGeneral() {
    _generalSub?.cancel(); _loadingGeneral = true; notifyListeners();
    _generalSub = _db.collection('forum_posts').where('isNational', isEqualTo: true).snapshots().listen(
          (snap) { _generalPosts = snap.docs.map(ForumPost.fromDoc).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)); _loadingGeneral = false; notifyListeners(); },
      onError: (e) { debugPrint('ForumProvider general error: $e'); _loadingGeneral = false; notifyListeners(); },
    );
  }

  List<ForumPost> filterCounty(String filter, String uid) {
    switch (filter) {
      case 'My Questions': return _countyPosts.where((p) => p.userId == uid).toList();
      case 'Unanswered':   return _countyPosts.where((p) => !p.isAnswered).toList();
      default:             return _countyPosts;
    }
  }

  List<ForumPost> filterGeneral(String filter, String uid) {
    switch (filter) {
      case 'My Questions': return _generalPosts.where((p) => p.userId == uid).toList();
      case 'Unanswered':   return _generalPosts.where((p) => !p.isAnswered).toList();
      default:             return _generalPosts;
    }
  }

  Future<String?> addPost(ForumPost post) async {
    try { final ref = await _db.collection('forum_posts').add(post.toMap()); return ref.id; }
    catch (e) { debugPrint('addPost error: $e'); return null; }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final replies = await _db.collection('forum_posts').doc(postId).collection('replies').get();
      final batch = _db.batch();
      for (final r in replies.docs) { batch.delete(r.reference); }
      batch.delete(_db.collection('forum_posts').doc(postId));
      await batch.commit(); return true;
    } catch (e) { debugPrint('deletePost error: $e'); return false; }
  }

  Future<bool> togglePostLike(String postId, String uid) async {
    try {
      final ref = _db.collection('forum_posts').doc(postId);
      final doc = await ref.get(); final data = doc.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? []);
      if (likes.contains(uid)) { await ref.update({'likes': FieldValue.arrayRemove([uid])}); }
      else { await ref.update({'likes': FieldValue.arrayUnion([uid])}); }
      return true;
    } catch (e) { debugPrint('togglePostLike error: $e'); return false; }
  }

  Future<List<ForumReply>> getReplies(String postId) async {
    try {
      final snap = await _db.collection('forum_posts').doc(postId).collection('replies').orderBy('createdAt').get();
      return snap.docs.map(ForumReply.fromDoc).toList();
    } catch (_) {
      try {
        final snap = await _db.collection('forum_posts').doc(postId).collection('replies').get();
        return snap.docs.map(ForumReply.fromDoc).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      } catch (_) { return []; }
    }
  }

  Future<bool> addReply(String postId, ForumReply reply) async {
    try {
      final batch = _db.batch();
      final replyRef = _db.collection('forum_posts').doc(postId).collection('replies').doc();
      batch.set(replyRef, reply.toMap());
      batch.update(_db.collection('forum_posts').doc(postId), {'replyCount': FieldValue.increment(1), 'updatedAt': Timestamp.now()});
      await batch.commit(); return true;
    } catch (e) { debugPrint('addReply error: $e'); return false; }
  }

  Future<bool> deleteReply(String postId, String replyId) async {
    try {
      final batch = _db.batch();
      batch.delete(_db.collection('forum_posts').doc(postId).collection('replies').doc(replyId));
      batch.update(_db.collection('forum_posts').doc(postId), {'replyCount': FieldValue.increment(-1)});
      await batch.commit(); return true;
    } catch (e) { return false; }
  }

  Future<bool> markBestAnswer(String postId, String replyId) async {
    try {
      final batch = _db.batch();
      batch.update(_db.collection('forum_posts').doc(postId).collection('replies').doc(replyId), {'isBestAnswer': true});
      batch.update(_db.collection('forum_posts').doc(postId), {'isAnswered': true, 'bestReplyId': replyId, 'updatedAt': Timestamp.now()});
      await batch.commit(); return true;
    } catch (e) { return false; }
  }

  Future<bool> toggleReplyLike(String postId, String replyId, String uid) async {
    try {
      final ref = _db.collection('forum_posts').doc(postId).collection('replies').doc(replyId);
      final doc = await ref.get();
      final likes = List<String>.from((doc.data() as Map)['likes'] ?? []);
      if (likes.contains(uid)) { await ref.update({'likes': FieldValue.arrayRemove([uid])}); }
      else { await ref.update({'likes': FieldValue.arrayUnion([uid])}); }
      return true;
    } catch (_) { return false; }
  }

  Future<bool> incrementViewCount(String postId) async {
    try { await _db.collection('forum_posts').doc(postId).update({'viewCount': FieldValue.increment(1)}); return true; }
    catch (_) { return false; }
  }

  @override
  void dispose() { _countySub?.cancel(); _generalSub?.cancel(); super.dispose(); }
}