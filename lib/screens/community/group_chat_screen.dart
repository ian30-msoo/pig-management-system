// lib/screens/community/group_chat_screen.dart
// ✅ Fixed: overflow, emoji picker, reactions, long-press options, per-user isolation
// ✅ Removed: attach file button, mic icon
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class GroupMessage {
  final String    id, senderId, senderName, senderRole, content, type;
  final DateTime? timestamp;
  final String?   reaction;

  const GroupMessage({
    required this.id, required this.senderId, required this.senderName,
    required this.senderRole, required this.content,
    this.timestamp, required this.type, this.reaction,
  });

  factory GroupMessage.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      id:         doc.id,
      senderId:   d['senderId']   ?? '',
      senderName: d['senderName'] ?? 'Farmer',
      senderRole: d['senderRole'] ?? 'Pig Farmer',
      content:    d['content']    ?? '',
      timestamp:  (d['timestamp'] as Timestamp?)?.toDate(),
      type:       d['type']       ?? 'text',
      reaction:   d['reaction']   as String?,
    );
  }

  Color get avatarColor {
    final colors = [
      const Color(0xFF1E88E5), const Color(0xFF43A047), const Color(0xFFE53935),
      const Color(0xFF8E24AA), const Color(0xFFF4511E), const Color(0xFF00ACC1),
      const Color(0xFF3949AB), const Color(0xFF00897B),
    ];
    final hash = senderName.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }
}

class GroupChatScreen extends StatefulWidget {
  final String   groupId, groupName, groupDescription;
  final IconData groupIcon;
  final Color    groupIconColor;
  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groupDescription,
    required this.groupIcon,
    required this.groupIconColor,
  });
  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _db        = FirebaseFirestore.instance;
  final _ctrl      = TextEditingController();
  final _scroll    = ScrollController();
  bool  _sending   = false;
  bool  _hasText   = false;
  bool  _showEmoji = false;
  int   _prevCount = 0;

  // Emoji rows — no external package needed
  static const _emojiRows = [
    ['😀','😂','😊','😍','🥰','😎','🤔','😢','😡','👍'],
    ['👎','👏','🙏','✅','❌','💯','🔥','⚡','💪','🐷'],
    ['🐗','🌾','🌿','💰','📈','📉','🏥','💊','🌡️','🔬'],
    ['🥩','🍖','🌽','🥬','🌱','🚜','🏡','⚠️','📢','🎉'],
    ['❤️','💚','💙','🧡','💛','🤍','🖤','💜','🤎','💝'],
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Stream<List<GroupMessage>> get _stream => _db
      .collection('group_chats')
      .doc(widget.groupId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .limitToLast(300)
      .snapshots()
      .map((s) => s.docs.map(GroupMessage.fromDoc).toList());

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    if (mounted) {
      setState(() {
        _sending   = true;
        _hasText   = false;
        _showEmoji = false;
      });
    }

    final auth = context.read<AuthProvider>();
    final uid  = auth.uid  ?? '';
    final name = auth.user?.fullName ?? 'Farmer';
    final role = auth.user?.role    ?? 'Pig Farmer';

    try {
      final batch  = _db.batch();
      final msgRef = _db
          .collection('group_chats')
          .doc(widget.groupId)
          .collection('messages')
          .doc();
      final grpRef = _db.collection('group_chats').doc(widget.groupId);
      batch.set(msgRef, {
        'senderId':   uid,
        'senderName': name,
        'senderRole': role,
        'content':    text,
        'timestamp':  FieldValue.serverTimestamp(),
        'type':       'text',
      });
      batch.set(grpRef, {
        'lastMessage':     text,
        'lastSender':      name,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
      _scrollToBottom(delayed: true);
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _addReaction(GroupMessage msg, String emoji) async {
    try {
      await _db
          .collection('group_chats')
          .doc(widget.groupId)
          .collection('messages')
          .doc(msg.id)
          .update({'reaction': emoji});
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteMsg(GroupMessage msg) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete message?',
            style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        content: const Text('This message will be removed for everyone.',
            style: TextStyle(fontSize: 13, color: AppColors.gray600,
                fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.gray600, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db
          .collection('group_chats')
          .doc(widget.groupId)
          .collection('messages')
          .doc(msg.id)
          .delete();
    }
  }

  void _showMsgOptions(GroupMessage msg, bool isMe) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2))),
          const Align(alignment: Alignment.centerLeft,
              child: Text('REACT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.gray400, letterSpacing: 1,
                      fontFamily: 'Poppins'))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['👍','❤️','😂','😮','😢','🙏'].map((e) => GestureDetector(
              onTap: () => _addReaction(msg, e),
              child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray200)),
                  child: Center(child: Text(e,
                      style: const TextStyle(fontSize: 24)))),
            )).toList(),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.gray100, height: 1),
          const SizedBox(height: 6),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.copy_rounded,
                    color: AppColors.primary, size: 18)),
            title: const Text('Copy message',
                style: TextStyle(fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600, fontSize: 14)),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: msg.content));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Copied',
                    style: TextStyle(fontFamily: 'Poppins')),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ));
            },
          ),
          if (isMe) ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(width: 38, height: 38,
                decoration: BoxDecoration(color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_rounded,
                    color: AppColors.danger, size: 18)),
            title: const Text('Delete message',
                style: TextStyle(fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600, fontSize: 14,
                    color: AppColors.danger)),
            onTap: () {
              Navigator.pop(context);
              _deleteMsg(msg);
            },
          ),
        ]),
      ),
    );
  }

  void _scrollToBottom({bool delayed = false}) {
    void go() {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut);
      }
    }
    if (delayed) Future.delayed(const Duration(milliseconds: 150), go);
    else go();
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().uid ?? '';
    final mq  = MediaQuery.of(context);

    return GestureDetector(
      onTap: () {
        if (_showEmoji) setState(() => _showEmoji = false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: Column(children: [

          // ── AppBar ───────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(top: mq.padding.top + 6, bottom: 10),
            color: AppColors.primary,
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
                splashRadius: 20,
              ),
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.groupIcon, color: Colors.white, size: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.groupName,
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700, color: Colors.white,
                        fontFamily: 'Poppins'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(widget.groupDescription,
                    style: TextStyle(fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontFamily: 'Poppins')),
              ])),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 22),
                splashRadius: 20,
                onPressed: () => _showInfo(context),
              ),
            ]),
          ),

          // ── Messages ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<GroupMessage>>(
              stream: _stream,
              builder: (_, snap) {
                if (!snap.hasData &&
                    snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final msgs = snap.data ?? [];
                if (msgs.length > _prevCount) {
                  _prevCount = msgs.length;
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                }

                if (msgs.isEmpty) {
                  return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(width: 80, height: 80,
                            decoration: BoxDecoration(
                                color: widget.groupIconColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24)),
                            child: Icon(widget.groupIcon,
                                color: widget.groupIconColor, size: 40)),
                        const SizedBox(height: 16),
                        Text(widget.groupName,
                            style: const TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark, fontFamily: 'Poppins'),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(widget.groupDescription,
                              style: const TextStyle(fontSize: 13,
                                  color: AppColors.gray400,
                                  fontFamily: 'Poppins'),
                              textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8)]),
                          child: const Row(mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.waving_hand_rounded,
                                    color: AppColors.warning, size: 18),
                                SizedBox(width: 8),
                                Text('Be the first to say something!',
                                    style: TextStyle(fontSize: 13,
                                        color: AppColors.gray600,
                                        fontFamily: 'Poppins')),
                              ]),
                        ),
                      ]));
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg   = msgs[i];
                    final isMe  = msg.senderId == uid;
                    final prev  = i > 0 ? msgs[i - 1] : null;
                    final next  = i < msgs.length - 1 ? msgs[i + 1] : null;
                    final isFirst = prev == null ||
                        prev.senderId != msg.senderId;
                    final isLast  = next == null ||
                        next.senderId != msg.senderId;
                    final showDate = prev == null ||
                        !_sameDay(prev.timestamp, msg.timestamp);

                    return Column(children: [
                      if (showDate && msg.timestamp != null)
                        _DateDivider(msg.timestamp!),
                      if (msg.type == 'system')
                        _SystemMsg(msg.content)
                      else
                        Padding(
                          padding: EdgeInsets.only(
                              top:    isFirst && !showDate ? 4 : 1,
                              bottom: isLast ? 10 : 1),
                          child: _Bubble(
                            msg:         msg,
                            isMe:        isMe,
                            isFirst:     isFirst,
                            isLast:      isLast,
                            onLongPress: () => _showMsgOptions(msg, isMe),
                          ),
                        ),
                    ]);
                  },
                );
              },
            ),
          ),

          // ── Emoji picker ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: _showEmoji ? 200 : 0,
            color: Colors.white,
            child: _showEmoji
                ? Column(children: [
              const Divider(height: 1, color: AppColors.gray100),
              Expanded(child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(children: _emojiRows.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((e) => GestureDetector(
                        onTap: () {
                          _ctrl.text += e;
                          setState(() => _hasText = true);
                        },
                        child: Container(width: 34, height: 34,
                            alignment: Alignment.center,
                            child: Text(e,
                                style: const TextStyle(fontSize: 20))),
                      )).toList()),
                )).toList()),
              )),
            ])
                : const SizedBox.shrink(),
          ),

          // ── Input bar (no attach, no mic) ─────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, mq.padding.bottom + 10),
            decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 12,
                    offset: Offset(0, -2))]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [

              // Text field with emoji toggle
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                      minHeight: 48, maxHeight: 130),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: AppColors.gray200)),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Emoji toggle
                        GestureDetector(
                          onTap: () {
                            setState(() => _showEmoji = !_showEmoji);
                            FocusScope.of(context).unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 12, bottom: 12),
                            child: Icon(
                              _showEmoji
                                  ? Icons.keyboard_rounded
                                  : Icons.tag_faces_rounded,
                              color: _showEmoji
                                  ? AppColors.primary
                                  : AppColors.gray400,
                              size: 22,
                            ),
                          ),
                        ),

                        // Text input
                        Expanded(child: TextField(
                          controller: _ctrl,
                          maxLines: 6, minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(fontFamily: 'Poppins',
                              fontSize: 14, color: AppColors.dark),
                          onTap: () {
                            if (_showEmoji) {
                              setState(() => _showEmoji = false);
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type a message',
                            hintStyle: TextStyle(color: AppColors.gray400,
                                fontFamily: 'Poppins', fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                            isDense: true,
                          ),
                        )),
                        const SizedBox(width: 8),
                      ]),
                ),
              ),

              const SizedBox(width: 8),

              // Send button only
              GestureDetector(
                onTap: _hasText ? _send : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                      color: _hasText
                          ? AppColors.primary
                          : AppColors.gray200,
                      shape: BoxShape.circle,
                      boxShadow: _hasText ? [BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3))] : []),
                  child: _sending
                      ? const Center(child: SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)))
                      : Icon(Icons.send_rounded,
                      color: _hasText
                          ? Colors.white
                          : AppColors.gray400,
                      size: 22),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showInfo(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.5,
        decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  widget.groupIconColor,
                  widget.groupIconColor.withValues(alpha: 0.7)
                ]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24))),
            child: Row(children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(widget.groupIcon, color: Colors.white, size: 24)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.groupName,
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700, color: Colors.white,
                        fontFamily: 'Poppins')),
                Text(widget.groupDescription,
                    style: const TextStyle(fontSize: 12,
                        color: Colors.white70, fontFamily: 'Poppins')),
              ])),
              GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22)),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    _IRow(Icons.group_rounded, 'Type',
                        widget.groupId == 'general'
                            ? 'National — All Kenya'
                            : 'County — Local only'),
                    const Divider(height: 20, color: AppColors.gray100),
                    _IRow(Icons.shield_outlined, 'Rules',
                        'Farming topics only · Be respectful · No spam'),
                  ]),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.lightbulb_rounded,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Tips', style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Poppins')),
                        ]),
                        const SizedBox(height: 8),
                        ...[
                          (Icons.tag_faces_rounded,
                          'Tap face icon to open emoji picker'),
                          (Icons.touch_app_rounded,
                          'Long press a message to react or delete it'),
                          (Icons.copy_rounded,
                          'Long press your message to copy text'),
                        ].map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(children: [
                            Icon(t.$1, size: 14, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.$2,
                                style: const TextStyle(fontSize: 12,
                                    color: AppColors.gray600,
                                    fontFamily: 'Poppins'))),
                          ]),
                        )),
                      ]),
                ),
              ])),
        ]),
      ),
    );
  }
}

Widget _IRow(IconData icon, String label, String value) =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11,
                color: AppColors.gray400, fontFamily: 'Poppins')),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: AppColors.dark,
                fontFamily: 'Poppins')),
          ])),
    ]);

// ── MESSAGE BUBBLE ────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final GroupMessage msg;
  final bool isMe, isFirst, isLast;
  final VoidCallback? onLongPress;
  const _Bubble({required this.msg, required this.isMe, required this.isFirst,
    required this.isLast, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final time = msg.timestamp != null
        ? '${msg.timestamp!.hour.toString().padLeft(2, '0')}:${msg.timestamp!.minute.toString().padLeft(2, '0')}'
        : '';
    final isVet = msg.senderRole == 'Veterinarian';

    return Padding(
      padding: EdgeInsets.only(left: isMe ? 52 : 0, right: isMe ? 0 : 52),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && isFirst)
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                  color: msg.avatarColor, shape: BoxShape.circle),
              child: Center(child: Text(
                msg.senderName.isNotEmpty
                    ? msg.senderName[0].toUpperCase() : 'F',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800, color: Colors.white,
                    fontFamily: 'Poppins'),
              )),
            )
          else if (!isMe)
            const SizedBox(width: 36),

          Flexible(child: GestureDetector(
            onLongPress: onLongPress,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:     Radius.circular(!isMe && isFirst ? 4 : 18),
                    topRight:    Radius.circular(isMe && isFirst ? 4 : 18),
                    bottomLeft:  const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isMe && isFirst) ...[
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Flexible(child: Text(msg.senderName,
                              style: TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: msg.avatarColor,
                                  fontFamily: 'Poppins'),
                              overflow: TextOverflow.ellipsis)),
                          if (isVet) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.medical_services_rounded,
                                        size: 10,
                                        color: Color(0xFF0EA5E9)),
                                    SizedBox(width: 3),
                                    Text('Vet', style: TextStyle(fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0EA5E9),
                                        fontFamily: 'Poppins')),
                                  ]),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 3),
                      ],

                      Text(msg.content, style: TextStyle(fontSize: 14,
                          color: isMe ? Colors.white : AppColors.dark,
                          fontFamily: 'Poppins', height: 1.4)),
                      const SizedBox(height: 3),

                      Align(alignment: Alignment.bottomRight,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(time, style: TextStyle(fontSize: 10,
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : AppColors.gray400,
                                fontFamily: 'Poppins')),
                            if (isMe) ...[
                              const SizedBox(width: 3),
                              Icon(Icons.done_all_rounded, size: 14,
                                  color: Colors.white.withValues(alpha: 0.8)),
                            ],
                          ])),
                    ]),
              ),
              if (msg.reaction != null)
                Positioned(
                  bottom: -10,
                  right: isMe ? 4 : null,
                  left:  isMe ? null : 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gray200),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4)]),
                    child: Text(msg.reaction!,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
            ]),
          )),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider(this.date);

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(date.year, date.month, date.day);
    String label;
    if (d == today) {
      label = 'Today';
    } else if (d == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = '${date.day} '
          '${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][date.month - 1]}'
          ' ${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(
            color: AppColors.gray200.withValues(alpha: 0.8), thickness: 1)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6)]),
          child: Text(label, style: const TextStyle(fontSize: 11,
              fontWeight: FontWeight.w600, color: AppColors.gray600,
              fontFamily: 'Poppins')),
        ),
        Expanded(child: Divider(
            color: AppColors.gray200.withValues(alpha: 0.8), thickness: 1)),
      ]),
    );
  }
}

class _SystemMsg extends StatelessWidget {
  final String text;
  const _SystemMsg(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]),
      child: Text(text, style: const TextStyle(fontSize: 11,
          color: AppColors.gray600, fontFamily: 'Poppins',
          fontWeight: FontWeight.w500)),
    )),
  );
}