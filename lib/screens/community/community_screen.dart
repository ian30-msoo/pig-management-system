// lib/screens/community/community_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'group_chat_screen.dart';

String _countyGroupId(String county) =>
    'county_${county.toLowerCase().replaceAll(' ', '_').replaceAll("'", '').replaceAll('-', '_')}';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth          = context.watch<AuthProvider>();
    final county        = auth.user?.displayCounty ?? '';
    final countyGroupId = county.isNotEmpty ? _countyGroupId(county) : '';
    final communities   = List<String>.from(auth.user?.communities ?? []);
    final mq            = MediaQuery.of(context);

    final bool joinedCounty  = county.isNotEmpty && communities.contains(county);
    final bool joinedGeneral = communities.contains('General');

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [

        // ── Header ─────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: mq.padding.top + 14, left: 20, right: 20, bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Community',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                        color: Colors.white, fontFamily: 'Poppins')),
                Text(
                    county.isNotEmpty ? '$county · Kenya' : 'Pig Farmers Network',
                    style: TextStyle(fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontFamily: 'Poppins')),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Groups', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 13, fontFamily: 'Poppins')),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _StatPill(Icons.location_on_rounded,
                  county.isNotEmpty ? county : 'No county set'),
              const SizedBox(width: 10),
              const _StatPill(Icons.public_rounded, 'Kenya Network'),
            ]),
          ]),
        ),

        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 20, bottom: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('YOUR GROUPS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.gray400, letterSpacing: 1.5,
                    fontFamily: 'Poppins')),
          ),
        ),

        // ── Groups ─────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [

              // County group
              if (countyGroupId.isNotEmpty) ...[
                _GroupTile(
                  groupId:   countyGroupId,
                  groupName: '$county Pig Farmers',
                  groupDesc: 'Local farmers in $county county',
                  icon:      Icons.location_on_rounded,
                  iconColor: AppColors.primary,
                  tagLabel:  county.toUpperCase(),
                  joined:    joinedCounty,
                  onTap: () => joinedCounty
                      ? _openChat(context,
                      groupId:   countyGroupId,
                      groupName: '$county Pig Farmers',
                      groupDesc: 'Local farmers in $county county',
                      icon:      Icons.location_on_rounded,
                      iconColor: AppColors.primary)
                      : _showJoinPrompt(context,
                      groupName:  '$county Pig Farmers',
                      communityKey: county,
                      auth:       auth),
                  onJoinToggle: () => _toggleMembership(
                      context: context,
                      auth:    auth,
                      key:     county,
                      joined:  joinedCounty),
                ),
                const SizedBox(height: 12),
              ],

              // General Kenya group
              _GroupTile(
                groupId:   'general',
                groupName: 'Kenya Pig Farmers Network',
                groupDesc: 'All pig farmers across Kenya',
                icon:      Icons.public_rounded,
                iconColor: AppColors.blue,
                tagLabel:  'NATIONAL',
                joined:    joinedGeneral,
                onTap: () => joinedGeneral
                    ? _openChat(context,
                    groupId:   'general',
                    groupName: 'Kenya Pig Farmers Network',
                    groupDesc: 'All pig farmers across Kenya',
                    icon:      Icons.public_rounded,
                    iconColor: AppColors.blue)
                    : _showJoinPrompt(context,
                    groupName:    'Kenya Pig Farmers Network',
                    communityKey: 'General',
                    auth:         auth),
                onJoinToggle: () => _toggleMembership(
                    context: context,
                    auth:    auth,
                    key:     'General',
                    joined:  joinedGeneral),
              ),

              const SizedBox(height: 20),

              // Rules card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Community Rules',
                            style: TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dark,
                                fontFamily: 'Poppins')),
                      ]),
                      const SizedBox(height: 12),
                      ...[
                        (Icons.agriculture_rounded,    'Pig farming topics only'),
                        (Icons.attach_money_rounded,   'Share market prices and deals'),
                        (Icons.local_hospital_rounded, 'Alert about disease outbreaks'),
                        (Icons.handshake_rounded,      'Be respectful to all members'),
                        (Icons.block_rounded,          'No spam or off-topic content'),
                      ].map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Icon(t.$1, size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.$2,
                              style: const TextStyle(fontSize: 12,
                                  color: AppColors.gray600,
                                  fontFamily: 'Poppins'))),
                        ]),
                      )),
                    ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Open chat ─────────────────────────────────────────────────────────────
  void _openChat(BuildContext ctx, {
    required String groupId, required String groupName,
    required String groupDesc, required IconData icon, required Color iconColor,
  }) {
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => GroupChatScreen(
      groupId:          groupId,
      groupName:        groupName,
      groupDescription: groupDesc,
      groupIcon:        icon,
      groupIconColor:   iconColor,
    )));
  }

  // ── Join prompt — shown when user taps a group they haven't joined ─────────
  void _showJoinPrompt(BuildContext ctx, {
    required String groupName,
    required String communityKey,
    required AuthProvider auth,
  }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(width: 64, height: 64,
              decoration: BoxDecoration(
                  color: AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.primary, size: 32)),
          const SizedBox(height: 16),
          Text('Join $groupName',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: AppColors.dark, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          const Text(
              'You need to join this community before you can read and send messages.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.gray400,
                  fontFamily: 'Poppins', height: 1.5)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _toggleMembership(
                    context: ctx, auth: auth,
                    key: communityKey, joined: false);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              child: Text('Join $groupName',
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: Colors.white,
                      fontFamily: 'Poppins')),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Maybe later',
                style: TextStyle(fontSize: 13, color: AppColors.gray400,
                    fontFamily: 'Poppins')),
          ),
        ]),
      ),
    );
  }

  // ── Join / leave toggle ───────────────────────────────────────────────────
  Future<void> _toggleMembership({
    required BuildContext context,
    required AuthProvider auth,
    required String key,
    required bool joined,
  }) async {
    final current = List<String>.from(auth.user?.communities ?? []);
    if (joined) {
      current.remove(key);
    } else {
      if (!current.contains(key)) current.add(key);
    }
    await auth.updateProfile({'communities': current});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(joined ? Icons.exit_to_app_rounded : Icons.check_circle_rounded,
              color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(joined ? 'Left the community' : 'Joined successfully!',
              style: const TextStyle(fontFamily: 'Poppins')),
        ]),
        backgroundColor: joined ? AppColors.gray600 : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STAT PILL
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.white70),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white,
          fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  GROUP TILE  — real-time last message + join/leave button
// ─────────────────────────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  final String     groupId, groupName, groupDesc, tagLabel;
  final IconData   icon;
  final Color      iconColor;
  final bool       joined;
  final VoidCallback onTap;
  final VoidCallback onJoinToggle;

  const _GroupTile({
    required this.groupId,   required this.groupName,
    required this.groupDesc, required this.tagLabel,
    required this.icon,      required this.iconColor,
    required this.joined,    required this.onTap,
    required this.onJoinToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('group_chats')
          .doc(groupId)
          .snapshots(),
      builder: (_, snap) {
        String lastMsg    = joined ? 'Tap to open chat' : 'Join to read messages';
        String lastSender = '';
        String timeStr    = '';
        bool   hasMsg     = false;

        if (joined && snap.hasData && snap.data!.exists) {
          final d   = snap.data!.data() as Map<String, dynamic>? ?? {};
          hasMsg     = d['lastMessage'] != null;
          lastMsg    = d['lastMessage']?.toString() ?? 'Tap to open chat';
          lastSender = d['lastSender']?.toString() ?? '';
          final ts   = (d['lastMessageTime'] as Timestamp?)?.toDate();
          if (ts != null) timeStr = _fmtTime(ts);
        }

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: joined
                      ? iconColor.withValues(alpha: 0.30)
                      : AppColors.gray200,
                  width: joined ? 1.5 : 1),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(children: [

              // Main row
              Row(children: [
                // Icon avatar + online dot
                Stack(children: [
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                        color: joined
                            ? iconColor.withValues(alpha: 0.12)
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: joined
                                ? iconColor.withValues(alpha: 0.2)
                                : AppColors.gray200,
                            width: 1.5)),
                    child: Icon(icon,
                        color: joined ? iconColor : AppColors.gray400,
                        size: 28),
                  ),
                  if (joined)
                    Positioned(bottom: 1, right: 1,
                        child: Container(width: 13, height: 13,
                            decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2)))),
                ]),
                const SizedBox(width: 14),

                // Text block
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(groupName,
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: joined
                                    ? AppColors.dark
                                    : AppColors.gray400,
                                fontFamily: 'Poppins'),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (joined && timeStr.isNotEmpty)
                          Text(timeStr,
                              style: TextStyle(fontSize: 10,
                                  color: hasMsg
                                      ? iconColor
                                      : AppColors.gray400,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: joined
                                  ? iconColor.withValues(alpha: 0.1)
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(tagLabel,
                              style: TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: joined
                                      ? iconColor
                                      : AppColors.gray400,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Poppins')),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          joined && hasMsg
                              ? (lastSender.isNotEmpty
                              ? '$lastSender: $lastMsg'
                              : lastMsg)
                              : lastMsg,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12,
                              color: joined && hasMsg
                                  ? AppColors.gray600
                                  : AppColors.gray400,
                              fontFamily: 'Poppins'),
                        )),
                      ]),
                      const SizedBox(height: 2),
                      Text(groupDesc, style: const TextStyle(fontSize: 11,
                          color: AppColors.gray400, fontFamily: 'Poppins')),
                    ])),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
              ]),

              // Join / Leave action strip
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onJoinToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                      color: joined
                          ? AppColors.gray100
                          : iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: joined
                              ? AppColors.gray200
                              : iconColor.withValues(alpha: 0.35))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          joined
                              ? Icons.exit_to_app_rounded
                              : Icons.group_add_rounded,
                          size: 15,
                          color: joined ? AppColors.gray400 : iconColor,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          joined ? 'Leave Community' : 'Join Community',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: joined ? AppColors.gray400 : iconColor),
                        ),
                      ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  String _fmtTime(DateTime dt) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = DateTime(dt.year, dt.month, dt.day);
    if (d == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}