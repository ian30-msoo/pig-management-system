// lib/providers/pig_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pig_model.dart';

class PigProvider extends ChangeNotifier {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── State ──────────────────────────────────────────────────────────────────
  List<PigModel>    _pigs    = [];
  List<HealthRecord> _health  = [];
  List<FeedRecord>  _feeding = [];
  bool    _loading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<PigModel>    get pigs    => List.unmodifiable(_pigs);
  List<HealthRecord> get health  => List.unmodifiable(_health);
  List<FeedRecord>  get feeding => List.unmodifiable(_feeding);
  bool    get loading => _loading;
  String? get error   => _error;

  List<PigModel> get activePigs     => _pigs.where((p) => p.isActive).toList();
  int get totalPigs                  => activePigs.length;
  int get healthyCount               => _pigs.where((p) => p.status == PigStatus.healthy).length;
  int get sickCount                  => _pigs.where((p) => p.status == PigStatus.sick).length;
  int get quarantineCount            => _pigs.where((p) => p.status == PigStatus.quarantine).length;

  /// Health records with active/critical status — shown as alerts
  List<HealthRecord> getAlerts() => _health
      .where((h) => h.status == 'ongoing' || h.status == 'critical')
      .toList();

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _pigsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('pigs');
  }

  // ── Subscriptions ──────────────────────────────────────────────────────────
  void Function()? _unsubPigs;
  void Function()? _unsubHealth;
  void Function()? _unsubFeeding;

  /// Call once after login — no userId arg needed (reads from FirebaseAuth)
  void init() {
    _subscribePigs();
    _subscribeHealth();
    _subscribeFeeding();
  }

  void _subscribePigs() {
    final ref = _pigsRef;
    if (ref == null) return;
    _setLoading(true);
    final sub = ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
        _pigs = snap.docs.map(PigModel.fromDoc).toList();
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
        notifyListeners();
      },
    );
    _unsubPigs = sub.cancel;
  }

  void _subscribeHealth() {
    final uid = _uid;
    if (uid == null) return;
    // collectionGroup needs a composite index — silently ignored until created
    final sub = _db
        .collectionGroup('health')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snap) {
        _health = snap.docs.map(HealthRecord.fromDoc).toList();
        notifyListeners();
      },
      onError: (_) {},
    );
    _unsubHealth = sub.cancel;
  }

  void _subscribeFeeding() {
    final uid = _uid;
    if (uid == null) return;
    final sub = _db
        .collectionGroup('feeding')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snap) {
        _feeding = snap.docs.map(FeedRecord.fromDoc).toList();
        notifyListeners();
      },
      onError: (_) {},
    );
    _unsubFeeding = sub.cancel;
  }

  // ── Reset / dispose ────────────────────────────────────────────────────────
  void reset() {
    _unsubPigs?.call();
    _unsubHealth?.call();
    _unsubFeeding?.call();
    _pigs    = [];
    _health  = [];
    _feeding = [];
    _loading = false;
    _error   = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _unsubPigs?.call();
    _unsubHealth?.call();
    _unsubFeeding?.call();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PIG CRUD
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> addPig(PigModel pig) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final map = pig.toMap()..['userId'] = _uid;
      await ref.add(map);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePig(PigModel pig) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final map = pig.toMap();
      map['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await ref.doc(pig.id).update(map);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePigFields(String pigId, Map<String, dynamic> data) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await ref.doc(pigId).update(data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HEALTH RECORDS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<HealthRecord>> getPigHealth(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return [];
      final snap = await ref
          .doc(pigId)
          .collection('health')
          .orderBy('date', descending: true)
          .get();
      return snap.docs.map(HealthRecord.fromDoc).toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a health record.
  /// [pigId] is required. Pass the record created from the UI.
  /// userId is injected automatically from FirebaseAuth.
  Future<bool> addHealthRecord(String pigId, HealthRecord record) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final map = record.toMap()..['userId'] = _uid;
      await ref.doc(pigId).collection('health').add(map);
      if (record.type == 'Treatment') {
        await updatePigStatus(pigId, PigStatus.sick);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteHealthRecord(String pigId, String recordId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('health').doc(recordId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FEED RECORDS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<FeedRecord>> getPigFeeding(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return [];
      final snap = await ref
          .doc(pigId)
          .collection('feeding')
          .orderBy('date', descending: true)
          .get();
      return snap.docs.map(FeedRecord.fromDoc).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addFeedRecord(String pigId, FeedRecord record) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final map = record.toMap()..['userId'] = _uid;
      await ref.doc(pigId).collection('feeding').add(map);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFeedRecord(String pigId, String recordId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('feeding').doc(recordId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WEIGHT / GROWTH RECORDS
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<WeightRecord>> getPigWeightHistory(String pigId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return [];
      final snap = await ref
          .doc(pigId)
          .collection('weight')
          .orderBy('date')
          .get();
      return snap.docs.map(WeightRecord.fromDoc).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addWeightRecord(String pigId, double weightKg,
      {String? notes}) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      final now = DateTime.now();
      final record = WeightRecord(
        id:        '',
        pigId:     pigId,
        weightKg:  weightKg,
        notes:     notes,
        date:      now,
        createdAt: now,
      );
      await ref.doc(pigId).collection('weight').add(record.toMap());
      await updatePigWeight(pigId, weightKg);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWeightRecord(String pigId, String recordId) async {
    try {
      final ref = _pigsRef;
      if (ref == null) return false;
      await ref.doc(pigId).collection('weight').doc(recordId).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}