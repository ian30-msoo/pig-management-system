// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FEEDING RECORD  (legacy — keep for Finance/Dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class FeedingRecord {
  final String id, userId, pigId, pigName, feedType, unit;
  final double quantity;
  final DateTime feedTime, createdAt;
  final String? notes;

  FeedingRecord({
    required this.id, required this.userId, required this.pigId,
    required this.pigName, required this.feedType, required this.quantity,
    required this.unit, required this.feedTime, this.notes, required this.createdAt,
  });

  factory FeedingRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FeedingRecord(
      id: doc.id, userId: d['userId'] ?? '', pigId: d['pigId'] ?? '',
      pigName: d['pigName'] ?? '', feedType: d['feedType'] ?? '',
      quantity: (d['quantity'] as num?)?.toDouble() ?? 0, unit: d['unit'] ?? 'kg',
      feedTime: (d['feedTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: d['notes'], createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() => {
    'userId': userId, 'pigId': pigId, 'pigName': pigName,
    'feedType': feedType, 'quantity': quantity, 'unit': unit,
    'feedTime': feedTime, 'notes': notes, 'createdAt': createdAt,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRANSACTION MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum TransactionType { sale, expense, income }

class TransactionModel {
  final String id, userId, category, description;
  final TransactionType type;
  final double amount;
  final DateTime date, createdAt;
  final String? pigId, pigName, receiptUrl;

  TransactionModel({
    required this.id, required this.userId, required this.type,
    required this.category, required this.description, required this.amount,
    required this.date, this.pigId, this.pigName, this.receiptUrl,
    required this.createdAt,
  });

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id, userId: d['userId'] ?? '',
      type: TransactionType.values.firstWhere(
              (t) => t.name == d['type'], orElse: () => TransactionType.expense),
      category: d['category'] ?? '', description: d['description'] ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pigId: d['pigId'], pigName: d['pigName'], receiptUrl: d['receiptUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() => {
    'userId': userId, 'type': type.name, 'category': category,
    'description': description, 'amount': amount, 'date': date,
    'pigId': pigId, 'pigName': pigName, 'receiptUrl': receiptUrl,
    'createdAt': createdAt,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMMUNITY POST  (legacy — kept for CommunityProvider)
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPost {
  final String id, userId, authorName, authorRole, content, category;
  final String? authorPhoto, imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  CommunityPost({
    required this.id, required this.userId, required this.authorName,
    required this.authorRole, this.authorPhoto, required this.content,
    required this.category, required this.likes, required this.commentCount,
    this.imageUrl, required this.createdAt,
  });

  bool isLikedBy(String uid) => likes.contains(uid);

  factory CommunityPost.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id, userId: d['userId'] ?? '', authorName: d['authorName'] ?? '',
      authorRole: d['authorRole'] ?? '', authorPhoto: d['authorPhoto'],
      content: d['content'] ?? '', category: d['category'] ?? 'general',
      likes: List<String>.from(d['likes'] ?? []), commentCount: d['commentCount'] ?? 0,
      imageUrl: d['imageUrl'], createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  Map<String, dynamic> toMap() => {
    'userId': userId, 'authorName': authorName, 'authorRole': authorRole,
    'authorPhoto': authorPhoto, 'content': content, 'category': category,
    'likes': likes, 'commentCount': commentCount, 'imageUrl': imageUrl,
    'createdAt': createdAt,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORUM POST  — advisory / Q&A platform model
// ─────────────────────────────────────────────────────────────────────────────

/// Author badge levels
enum AuthorBadge { farmer, expertFarmer, verifiedVet, admin }

extension AuthorBadgeX on AuthorBadge {
  String get label {
    switch (this) {
      case AuthorBadge.verifiedVet:   return 'Verified Vet';
      case AuthorBadge.expertFarmer:  return 'Expert Farmer';
      case AuthorBadge.admin:         return 'Admin';
      default:                        return 'Farmer';
    }
  }
  // Returns null for plain farmer (no badge shown)
  String? get badgeEmoji {
    switch (this) {
      case AuthorBadge.verifiedVet:   return '🩺';
      case AuthorBadge.expertFarmer:  return '⭐';
      case AuthorBadge.admin:         return '🛡️';
      default:                        return null;
    }
  }
}

/// Forum post categories
const List<String> forumCategories = [
  'Health', 'Feeding', 'Breeding', 'Market', 'General',
];

class ForumPost {
  final String id;
  final String userId;
  final String authorName;
  final String authorRole;
  final AuthorBadge authorBadge;
  final String? authorPhoto;

  final String title;
  final String description;
  final String category;    // one of forumCategories
  final String county;      // author's county
  final bool isNational;    // true = posted to General/national forum
  final bool isAnswered;
  final String? bestReplyId;
  final int replyCount;
  final int viewCount;

  final List<String> taggedUserIds;
  final List<String> likes;        // ✅ post-level likes
  final String? imageUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  ForumPost({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.authorRole,
    required this.authorBadge,
    this.authorPhoto,
    required this.title,
    required this.description,
    required this.category,
    required this.county,
    required this.isNational,
    required this.isAnswered,
    this.bestReplyId,
    required this.replyCount,
    required this.viewCount,
    required this.taggedUserIds,
    required this.likes,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ForumPost.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ForumPost(
      id:           doc.id,
      userId:       d['userId']       ?? '',
      authorName:   d['authorName']   ?? '',
      authorRole:   d['authorRole']   ?? '',
      authorBadge:  AuthorBadge.values.firstWhere(
              (b) => b.name == (d['authorBadge'] ?? 'farmer'),
          orElse: () => AuthorBadge.farmer),
      authorPhoto:  d['authorPhoto'],
      title:        d['title']        ?? '',
      description:  d['description']  ?? '',
      category:     d['category']     ?? 'General',
      county:       d['county']       ?? '',
      isNational:   d['isNational']   ?? false,
      isAnswered:   d['isAnswered']   ?? false,
      bestReplyId:  d['bestReplyId'],
      replyCount:   d['replyCount']   ?? 0,
      viewCount:    d['viewCount']    ?? 0,
      taggedUserIds: List<String>.from(d['taggedUserIds'] ?? []),
      likes:        List<String>.from(d['likes'] ?? []),
      imageUrl:     d['imageUrl'],
      createdAt:    (d['createdAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:    (d['updatedAt']   as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId':       userId,
    'authorName':   authorName,
    'authorRole':   authorRole,
    'authorBadge':  authorBadge.name,
    'authorPhoto':  authorPhoto,
    'title':        title,
    'description':  description,
    'category':     category,
    'county':       county,
    'isNational':   isNational,
    'isAnswered':   isAnswered,
    'bestReplyId':  bestReplyId,
    'replyCount':   replyCount,
    'viewCount':    viewCount,
    'taggedUserIds': taggedUserIds,
    'likes':        likes,
    'imageUrl':     imageUrl,
    'createdAt':    createdAt,
    'updatedAt':    updatedAt,
  };

  bool isLikedBy(String uid) => likes.contains(uid);

  ForumPost copyWith({bool? isAnswered, String? bestReplyId, int? replyCount}) =>
      ForumPost(
        id: id, userId: userId, authorName: authorName, authorRole: authorRole,
        authorBadge: authorBadge, authorPhoto: authorPhoto, title: title,
        description: description, category: category, county: county,
        isNational: isNational,
        isAnswered: isAnswered ?? this.isAnswered,
        bestReplyId: bestReplyId ?? this.bestReplyId,
        replyCount: replyCount ?? this.replyCount,
        viewCount: viewCount, taggedUserIds: taggedUserIds,
        likes: likes, imageUrl: imageUrl,
        createdAt: createdAt, updatedAt: DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORUM REPLY
// ─────────────────────────────────────────────────────────────────────────────

class ForumReply {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String authorRole;
  final AuthorBadge authorBadge;
  final String? authorPhoto;
  final String content;
  final bool isBestAnswer;
  final List<String> likes;
  final DateTime createdAt;

  ForumReply({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorRole,
    required this.authorBadge,
    this.authorPhoto,
    required this.content,
    required this.isBestAnswer,
    required this.likes,
    required this.createdAt,
  });

  bool isLikedBy(String uid) => likes.contains(uid);

  factory ForumReply.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ForumReply(
      id:          doc.id,
      postId:      d['postId']     ?? '',
      userId:      d['userId']     ?? '',
      authorName:  d['authorName'] ?? '',
      authorRole:  d['authorRole'] ?? '',
      authorBadge: AuthorBadge.values.firstWhere(
              (b) => b.name == (d['authorBadge'] ?? 'farmer'),
          orElse: () => AuthorBadge.farmer),
      authorPhoto: d['authorPhoto'],
      content:     d['content']    ?? '',
      isBestAnswer: d['isBestAnswer'] ?? false,
      likes:       List<String>.from(d['likes'] ?? []),
      createdAt:   (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'postId':      postId,
    'userId':      userId,
    'authorName':  authorName,
    'authorRole':  authorRole,
    'authorBadge': authorBadge.name,
    'authorPhoto': authorPhoto,
    'content':     content,
    'isBestAnswer': isBestAnswer,
    'likes':       likes,
    'createdAt':   createdAt,
  };
}