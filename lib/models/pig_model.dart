// lib/models/pig_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PigStatus { healthy, sick, quarantine, sold, deceased }

extension PigStatusX on PigStatus {
  String get label {
    switch (this) {
      case PigStatus.healthy:    return 'Healthy';
      case PigStatus.sick:       return 'Sick';
      case PigStatus.quarantine: return 'Quarantine';
      case PigStatus.sold:       return 'Sold';
      case PigStatus.deceased:   return 'Deceased';
    }
  }
  Color get color {
    switch (this) {
      case PigStatus.healthy:    return const Color(0xFF10B981);
      case PigStatus.sick:       return const Color(0xFFE8253F);
      case PigStatus.quarantine: return const Color(0xFFF59E0B);
      case PigStatus.sold:       return const Color(0xFF6B7280);
      case PigStatus.deceased:   return const Color(0xFF374151);
    }
  }
  Color get bgColor {
    switch (this) {
      case PigStatus.healthy:    return const Color(0xFFD1FAE5);
      case PigStatus.sick:       return const Color(0xFFFEE2E2);
      case PigStatus.quarantine: return const Color(0xFFFEF3C7);
      case PigStatus.sold:       return const Color(0xFFF3F4F6);
      case PigStatus.deceased:   return const Color(0xFFE5E7EB);
    }
  }
}

enum PigGender { male, female }

// ─────────────────────────────────────────────────────────────────────────────
//  PIG MODEL
// ─────────────────────────────────────────────────────────────────────────────

class PigModel {
  final String    id;
  final String    userId;
  final String    name;
  final String    tagId;
  final String    breed;
  final PigGender gender;
  final DateTime  birthDate;
  final double    weight;
  final String    stage;
  final PigStatus status;
  final String?   notes;
  final String?   imageUrl;   // ← pig photo
  final String?   location;  // ← pen / room / shed
  final DateTime  createdAt;
  final DateTime  updatedAt;

  const PigModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.tagId,
    required this.breed,
    required this.gender,
    required this.birthDate,
    required this.weight,
    required this.stage,
    required this.status,
    this.notes,
    this.imageUrl,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      status != PigStatus.sold && status != PigStatus.deceased;

  String get stageEmoji {
    switch (stage.toLowerCase()) {
      case 'piglet':   return '🐷';
      case 'weaner':   return '🐽';
      case 'grower':   return '🐖';
      case 'finisher': return '🐗';
      case 'boar':     return '🐗';
      case 'sow':      return '🐷';
      default:         return '🐖';
    }
  }

  String get ageLabel {
    final diff   = DateTime.now().difference(birthDate);
    final months = (diff.inDays / 30).floor();
    if (months < 1)  return '${diff.inDays}d';
    if (months < 12) return '${months}mo';
    final years = (months / 12).floor();
    final rem   = months % 12;
    return rem > 0 ? '${years}y ${rem}mo' : '${years}y';
  }

  factory PigModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PigModel(
      id:        doc.id,
      userId:    d['userId']    ?? '',
      name:      d['name']      ?? '',
      tagId:     d['tagId']     ?? '',
      breed:     d['breed']     ?? 'Mixed',
      gender:    d['gender'] == 'female' ? PigGender.female : PigGender.male,
      birthDate: (d['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight:    (d['weight']   as num?)?.toDouble() ?? 0,
      stage:     d['stage']     ?? 'Grower',
      status:    PigStatus.values.firstWhere(
            (s) => s.name == (d['status'] ?? 'healthy'),
        orElse: () => PigStatus.healthy,
      ),
      notes:     d['notes'],
      imageUrl:  d['imageUrl'],
      location:  d['location'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId':    userId,
    'name':      name,
    'tagId':     tagId,
    'breed':     breed,
    'gender':    gender.name,
    'birthDate': birthDate,
    'weight':    weight,
    'stage':     stage,
    'status':    status.name,
    'notes':     notes,
    'imageUrl':  imageUrl,
    'location':  location,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  PigModel copyWith({
    String? id, String? userId, String? name, String? tagId,
    String? breed, PigGender? gender, DateTime? birthDate,
    double? weight, String? stage, PigStatus? status,
    String? notes, String? imageUrl, String? location,
    DateTime? createdAt, DateTime? updatedAt,
  }) =>
      PigModel(
        id:        id        ?? this.id,
        userId:    userId    ?? this.userId,
        name:      name      ?? this.name,
        tagId:     tagId     ?? this.tagId,
        breed:     breed     ?? this.breed,
        gender:    gender    ?? this.gender,
        birthDate: birthDate ?? this.birthDate,
        weight:    weight    ?? this.weight,
        stage:     stage     ?? this.stage,
        status:    status    ?? this.status,
        notes:     notes     ?? this.notes,
        imageUrl:  imageUrl  ?? this.imageUrl,
        location:  location  ?? this.location,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEALTH RECORD   users/{uid}/pigs/{pigId}/health/{id}
// ─────────────────────────────────────────────────────────────────────────────

class HealthRecord {
  final String  id;
  final String  pigId;
  final String  pigName;
  final String  type;
  final String  condition;
  final String? treatment;
  final String? veterinarian;
  final double? temperature;
  final String  status;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  HealthRecord({
    required this.id,
    required this.pigId,
    required this.pigName,
    required this.type,
    required this.condition,
    this.treatment,
    this.veterinarian,
    this.temperature,
    this.status = 'ongoing',
    this.notes,
    required this.date,
    required this.createdAt,
  });

  String?  get vetName    => veterinarian;
  DateTime get recordDate => date;

  factory HealthRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HealthRecord(
      id:           doc.id,
      pigId:        d['pigId']        ?? '',
      pigName:      d['pigName']      ?? '',
      type:         d['type']         ?? 'Checkup',
      condition:    d['condition']    ?? '',
      treatment:    d['treatment'],
      veterinarian: d['veterinarian'] ?? d['vetName'],
      temperature:  (d['temperature'] as num?)?.toDouble(),
      status:       d['status']       ?? 'ongoing',
      notes:        d['notes'],
      date: (d['date']       as Timestamp?)?.toDate() ??
          (d['recordDate'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'pigId':        pigId,
    'pigName':      pigName,
    'type':         type,
    'condition':    condition,
    'treatment':    treatment,
    'veterinarian': veterinarian,
    'temperature':  temperature,
    'status':       status,
    'notes':        notes,
    'date':         date,
    'createdAt':    createdAt,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  FEED RECORD   users/{uid}/pigs/{pigId}/feeding/{id}
// ─────────────────────────────────────────────────────────────────────────────

class FeedRecord {
  final String  id;
  final String  pigId;
  final String? pigName;
  final String  feedType;
  final double  quantityKg;
  final String? brand;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  FeedRecord({
    required this.id,
    required this.pigId,
    this.pigName,
    required this.feedType,
    required this.quantityKg,
    this.brand,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  factory FeedRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FeedRecord(
      id:         doc.id,
      pigId:      d['pigId']    ?? '',
      pigName:    d['pigName'],
      feedType:   d['feedType'] ?? '',
      quantityKg: (d['quantityKg'] as num?)?.toDouble() ?? 0,
      brand:      d['brand'],
      notes:      d['notes'],
      date:       (d['date']      as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:  (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'pigId':      pigId,
    'pigName':    pigName,
    'feedType':   feedType,
    'quantityKg': quantityKg,
    'brand':      brand,
    'notes':      notes,
    'date':       date,
    'createdAt':  createdAt,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  WEIGHT RECORD   users/{uid}/pigs/{pigId}/weight/{id}
// ─────────────────────────────────────────────────────────────────────────────

class WeightRecord {
  final String  id;
  final String  pigId;
  final double  weightKg;
  final String? notes;
  final DateTime date;
  final DateTime createdAt;

  WeightRecord({
    required this.id,
    required this.pigId,
    required this.weightKg,
    this.notes,
    required this.date,
    required this.createdAt,
  });

  factory WeightRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return WeightRecord(
      id:        doc.id,
      pigId:     d['pigId']    ?? '',
      weightKg:  (d['weightKg'] as num?)?.toDouble() ?? 0,
      notes:     d['notes'],
      date:      (d['date']      as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'pigId':     pigId,
    'weightKg':  weightKg,
    'notes':     notes,
    'date':      date,
    'createdAt': createdAt,
  };
}