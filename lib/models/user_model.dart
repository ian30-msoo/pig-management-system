import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String? photoUrl;
  final String? county;
  final String? role;
  final String? farmName;
  final String? farmSize;
  final String? bio;
  final List<String> communities;
  final bool onboardingComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.photoUrl,
    this.county,
    this.role,
    this.farmName,
    this.farmSize,
    this.bio,
    this.communities = const [],
    this.onboardingComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────
  String get fullName => '$firstName $lastName'.trim();
  String get displayRole => (role?.isNotEmpty == true) ? role! : 'Farmer';
  String get displayCounty => (county?.isNotEmpty == true) ? county! : '';

  // ── fromDoc: build from Firestore DocumentSnapshot ────────────────────────
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(map, doc.id);
  }

  // ── fromMap: build from raw map + uid ─────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      county: map['county'] as String?,
      role: map['role'] as String?,
      farmName: map['farmName'] as String?,
      farmSize: map['farmSize'] as String?,
      bio: map['bio'] as String?,
      communities: _toStringList(map['communities']),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  // ── toMap: convert to Firestore-friendly map ──────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'photoUrl': photoUrl ?? '',
      'county': county ?? '',
      'role': role ?? 'Farmer',
      'farmName': farmName ?? '',
      'farmSize': farmSize ?? '',
      'bio': bio ?? '',
      'communities': communities,
      'onboardingComplete': onboardingComplete,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── copyWith ──────────────────────────────────────────────────────────────
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? photoUrl,
    String? county,
    String? role,
    String? farmName,
    String? farmSize,
    String? bio,
    List<String>? communities,
    bool? onboardingComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      county: county ?? this.county,
      role: role ?? this.role,
      farmName: farmName ?? this.farmName,
      farmSize: farmSize ?? this.farmSize,
      bio: bio ?? this.bio,
      communities: communities ?? this.communities,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}