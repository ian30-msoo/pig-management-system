// lib/screens/community/forum_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FORUM DETAIL SCREEN — Full question + organized replies
// ─────────────────────────────────────────────────────────────────────────────

class ForumDetailScreen extends StatefulWidget {
  final ForumPost post;
  final String uid;
  const ForumDetailScreen({super.key, required this.post, required this.uid});

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  List<ForumReply> _replies = [];
  bool _loading = true;
  bool _posting = false;
  final _replyCtrl = TextEditingController();
  late ForumPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadReplies();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await context.read<ForumProvider>().getReplies(_post.id);
    // Best answer first, then by date
    list.sort((a, b) {
      if (a.isBestAnswer && !b.isBestAnswer) return -1;
      if (!a.isBestAnswer && b.isBestAnswer)  return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    if (mounted) setState(() { _replies = list; _loading = false; });
  }

  Future<void> _postReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);

    final auth  = context.read<AuthProvider>();
    AuthorBadge badge = AuthorBadge.farmer;
    if ((auth.user?.role ?? '') == 'Veterinarian') badge = AuthorBadge.verifiedVet;

    final reply = ForumReply(
      id: '', postId: _post.id,
      userId:      auth.uid ?? '',
      authorName:  auth.user?.fullName ?? 'Farmer',
      authorRole:  auth.user?.role ?? 'Farmer',
      authorBadge: badge,
      authorPhoto: auth.user?.photoUrl,
      content:     text,
      isBestAnswer: false, likes: [],
      createdAt: DateTime.now(),
    );

    final ok = await context.read<ForumProvider>().addReply(_post.id, reply);
    if (ok) {
      _replyCtrl.clear();
      FocusScope.of(context).unfocus();
      await _loadReplies();
    }
    if (mounted) setState(() => _posting = false);
  }

  Future<void> _markBestAnswer(ForumReply reply) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Best Answer?',
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        content: Text(
            'Mark ${reply.authorName}\'s reply as the best answer?\n\nThis helps other farmers with the same problem.',
            style: const TextStyle(fontSize: 13, color: AppColors.gray600,
                fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray600, fontFamily: 'Poppins'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Mark It!', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await context.read<ForumProvider>().markBestAnswer(_post.id, reply.id);
      if (ok) {
        setState(() => _post = _post.copyWith(isAnswered: true, bestReplyId: reply.id));
        await _loadReplies();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Best answer marked! ✅', style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthor = _post.userId == widget.uid;
    final catColor = _categoryColor(_post.category);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [

        // ── Header ────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16, right: 16, bottom: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24)),
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_post.category,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'Poppins')),
                ),
                const SizedBox(height: 4),
                Text(_post.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white, fontFamily: 'Poppins', height: 1.3)),
              ]),
            ),
            const SizedBox(width: 8),
            // Answered badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _post.isAnswered
                      ? AppColors.success.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_post.isAnswered ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                    size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(_post.isAnswered ? 'Answered' : 'Open',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: Colors.white, fontFamily: 'Poppins')),
              ]),
            ),
          ]),
        ),

        // ── Body ──────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [

              // ── Full question card ────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Author
                  Row(children: [
                    _AuthorAvatar(name: _post.authorName, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(_post.authorName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.dark, fontFamily: 'Poppins')),
                          if (_post.authorBadge.badgeEmoji != null) ...[
                            const SizedBox(width: 6),
                            _BadgeChip(badge: _post.authorBadge),
                          ],
                        ]),
                        Text('${_post.county} · ${_timeAgo(_post.createdAt)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.gray400,
                                fontFamily: 'Poppins')),
                      ]),
                    ),
                    // Stats
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Row(children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 13, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text('${_post.replyCount}',
                            style: const TextStyle(fontSize: 12, color: AppColors.gray600,
                                fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                      ]),
                      Row(children: [
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 13, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text('${_post.viewCount}',
                            style: const TextStyle(fontSize: 12, color: AppColors.gray400,
                                fontFamily: 'Poppins')),
                      ]),
                    ]),
                  ]),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.gray100),
                  const SizedBox(height: 14),
                  // Full description
                  Text(_post.description,
                      style: const TextStyle(fontSize: 14, color: AppColors.gray600,
                          fontFamily: 'Poppins', height: 1.6)),
                ]),
              ),
              const SizedBox(height: 20),

              // ── Replies header ────────────────────────────────
              Row(children: [
                Text('${_replies.length} Answer${_replies.length != 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.dark, fontFamily: 'Poppins')),
                const Spacer(),
                if (_post.isAnswered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('Problem Solved ✅',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.success, fontFamily: 'Poppins')),
                  ),
              ]),
              const SizedBox(height: 12),

              // ── Reply cards ───────────────────────────────────
              if (_replies.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: const Column(children: [
                    Icon(Icons.question_answer_outlined, size: 40, color: AppColors.gray200),
                    SizedBox(height: 10),
                    Text('No answers yet',
                        style: TextStyle(fontSize: 14, color: AppColors.gray400,
                            fontFamily: 'Poppins')),
                    SizedBox(height: 4),
                    Text('Be the first to help!',
                        style: TextStyle(fontSize: 12, color: AppColors.gray400,
                            fontFamily: 'Poppins')),
                  ]),
                )
              else
                ..._replies.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReplyCard(
                    reply: reply,
                    uid: widget.uid,
                    isPostAuthor: isAuthor,
                    postAnswered: _post.isAnswered,
                    onMarkBest: () => _markBestAnswer(reply),
                    onDelete: () async {
                      await context.read<ForumProvider>()
                          .deleteReply(_post.id, reply.id);
                      await _loadReplies();
                    },
                    onLike: () async {
                      await context.read<ForumProvider>()
                          .toggleReplyLike(_post.id, reply.id, widget.uid);
                      await _loadReplies();
                    },
                  ),
                )),
              const SizedBox(height: 80),
            ],
          ),
        ),

        // ── Reply input ───────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12, offset: const Offset(0, -3))],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write your answer...',
                  hintStyle: const TextStyle(color: AppColors.gray400,
                      fontFamily: 'Poppins', fontSize: 13),
                  filled: true, fillColor: AppColors.offWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _posting ? null : _postReply,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14)),
                child: _posting
                    ? const Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'Health':   return AppColors.danger;
      case 'Feeding':  return AppColors.success;
      case 'Breeding': return const Color(0xFF8B5CF6);
      case 'Market':   return AppColors.blue;
      default:         return AppColors.warning;
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60)  return '${d.inMinutes}m ago';
    if (d.inHours   < 24)  return '${d.inHours}h ago';
    if (d.inDays    < 7)   return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REPLY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _ReplyCard extends StatelessWidget {
  final ForumReply reply;
  final String uid;
  final bool isPostAuthor;
  final bool postAnswered;
  final VoidCallback onMarkBest;
  final VoidCallback onLike;

  final VoidCallback onDelete;

  const _ReplyCard({
    required this.reply, required this.uid, required this.isPostAuthor,
    required this.postAnswered, required this.onMarkBest, required this.onLike,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = reply.isLikedBy(uid);
    final isBest  = reply.isBestAnswer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isBest
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: isBest
                  ? AppColors.success.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isBest ? 12 : 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Best answer banner
          if (isBest) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                SizedBox(width: 6),
                Text('Best Answer — Marked by question author',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.success, fontFamily: 'Poppins')),
              ]),
            ),
          ],

          // Author row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AuthorAvatar(name: reply.authorName, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(reply.authorName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.dark, fontFamily: 'Poppins')),
                  ),
                  if (reply.authorBadge.badgeEmoji != null) ...[
                    const SizedBox(width: 6),
                    _BadgeChip(badge: reply.authorBadge),
                  ],
                ]),
                Text(_timeAgo(reply.createdAt),
                    style: const TextStyle(fontSize: 10, color: AppColors.gray400,
                        fontFamily: 'Poppins')),
              ]),
            ),
          ]),
          const SizedBox(height: 10),

          // Reply content
          Text(reply.content,
              style: const TextStyle(fontSize: 13, color: AppColors.gray600,
                  fontFamily: 'Poppins', height: 1.6)),
          const SizedBox(height: 12),

          // Action row
          Row(children: [
            // Like button
            GestureDetector(
              onTap: onLike,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: isLiked ? AppColors.primaryBg : AppColors.gray100,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                      size: 14, color: isLiked ? AppColors.primary : AppColors.gray400),
                  const SizedBox(width: 5),
                  Text('${reply.likes.length}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: isLiked ? AppColors.primary : AppColors.gray400)),
                ]),
              ),
            ),
            const Spacer(),
            // Mark best answer (only post author can do this, and only if not answered)
            if (isPostAuthor && !isBest && !postAnswered)
              GestureDetector(
                onTap: onMarkBest,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                    SizedBox(width: 5),
                    Text('Best Answer',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.success, fontFamily: 'Poppins')),
                  ]),
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60)  return '${d.inMinutes}m ago';
    if (d.inHours   < 24)  return '${d.inHours}h ago';
    if (d.inDays    < 7)   return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _AuthorAvatar({required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        color: AppColors.primaryBg, shape: BoxShape.circle),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.42, fontWeight: FontWeight.w800,
          color: AppColors.primary, fontFamily: 'Poppins',
        ),
      ),
    ),
  );
}

class _BadgeChip extends StatelessWidget {
  final AuthorBadge badge;
  const _BadgeChip({required this.badge});

  Color get _color {
    switch (badge) {
      case AuthorBadge.verifiedVet:  return const Color(0xFF0EA5E9);
      case AuthorBadge.expertFarmer: return AppColors.warning;
      case AuthorBadge.admin:        return AppColors.primary;
      default:                       return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(badge.badgeEmoji ?? '', style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 3),
      Text(badge.label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: _color, fontFamily: 'Poppins')),
    ]),
  );
}