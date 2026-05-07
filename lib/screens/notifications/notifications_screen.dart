// lib/screens/notifications/notifications_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../models/pig_model.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../services/in_app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  List<PigAlert>  _aiAlerts    = [];
  List<FarmNews>  _newsAlerts  = [];
  List<Map<String, dynamic>> _firestoreNotifs = [];
  bool _aiLoading   = false;
  bool _newsLoading = false;
  String? _userId;

  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;

  // Track previously seen sick pigs to detect new changes
  Set<String> _knownSickPigIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<app_auth.AuthProvider>().user?.uid;
      _subscribeToFirestoreNotifs();
      _loadAiAlerts();
      _checkNewsForAlerts();
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  // ── Real-time Firestore notifications stream ───────────────────────────────
  void _subscribeToFirestoreNotifs() {
    if (_userId == null) return;
    _notifSub = FirestoreService.notificationsStream(_userId!).listen((notifs) {
      if (!mounted) return;
      // Show popup for new unread notifications
      final unread = notifs.where((n) => n['read'] == false).toList();
      if (unread.isNotEmpty && _firestoreNotifs.isNotEmpty) {
        final latestNew = unread.firstWhere(
              (n) => !_firestoreNotifs.any((old) => old['id'] == n['id']),
          orElse: () => <String, dynamic>{},
        );
        if (latestNew.isNotEmpty && mounted) {
          InAppNotification.show(
            context,
            title: latestNew['title'] ?? 'Farm Alert',
            body:  latestNew['message'] ?? '',
            color: _notifColor(latestNew['type'] ?? 'info'),
            icon:  _notifIcon(latestNew['type'] ?? 'info'),
          );
        }
      }
      setState(() => _firestoreNotifs = notifs);
    });
  }

  // ── Load AI alerts from pig data ───────────────────────────────────────────
  Future<void> _loadAiAlerts() async {
    if (_aiLoading || !mounted) return;
    setState(() => _aiLoading = true);
    try {
      final pigs = context.read<PigProvider>().activePigs;
      if (pigs.isEmpty) { setState(() => _aiLoading = false); return; }

      final pigsData = pigs.map((p) => {
        'id': p.id, 'name': p.name, 'tagId': p.tagId,
        'stage': p.stage, 'weight': p.weight,
        'ageLabel': p.ageLabel, 'status': p.status.label, 'breed': p.breed,
      }).toList();

      final alerts = await AiService.generateAlerts(pigsData: pigsData);
      if (!mounted) return;

      // Show popup for critical AI alerts
      final critical = alerts.where((a) => a.alertType == 'critical').toList();
      for (final alert in critical.take(1)) {
        InAppNotification.show(
          context,
          title: alert.title,
          body: alert.message,
          color: AppColors.danger,
          icon: Icons.emergency_rounded,
        );
      }

      setState(() { _aiAlerts = alerts; _aiLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── Check news for high-priority alerts ────────────────────────────────────
  Future<void> _checkNewsForAlerts() async {
    if (_newsLoading || !mounted) return;
    setState(() => _newsLoading = true);
    try {
      final news = await AiService.fetchLatestNews();
      if (!mounted) return;

      // Show popup for high-priority news (e.g. ASF alerts)
      final highPrio = news.where((n) => n.relevance == 'high' && n.category == 'Health Alert').toList();
      if (highPrio.isNotEmpty) {
        final top = highPrio.first;
        // Small delay so it doesn't overlap with AI alert popup
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          InAppNotification.show(
            context,
            title: top.title,
            body: top.summary.length > 80 ? '${top.summary.substring(0, 77)}...' : top.summary,
            color: AppColors.danger,
            icon: Icons.newspaper_rounded,
            duration: const Duration(seconds: 6),
          );
        }
      }

      setState(() { _newsAlerts = news; _newsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _newsLoading = false);
    }
  }

  // ── Refresh all ────────────────────────────────────────────────────────────
  Future<void> _refreshAll() async {
    await Future.wait([_loadAiAlerts(), _checkNewsForAlerts()]);
  }

  // ── Watch for newly sick pigs and show popup ───────────────────────────────
  void _checkForNewSickPigs(List<PigModel> sickPigs) {
    final currentIds = sickPigs.map((p) => p.id).toSet();
    final newSick = currentIds.difference(_knownSickPigIds);
    if (newSick.isNotEmpty && _knownSickPigIds.isNotEmpty) {
      final pig = sickPigs.firstWhere((p) => newSick.contains(p.id), orElse: () => sickPigs.first);
      InAppNotification.show(
        context,
        title: '${pig.name} Needs Attention!',
        body: '${pig.name} (${pig.tagId}) status changed to ${pig.status.label}. Take action now.',
        color: pig.status == PigStatus.quarantine ? AppColors.warning : AppColors.danger,
        icon: Icons.medical_services_rounded,
      );
    }
    _knownSickPigIds = currentIds;
  }

  Color _notifColor(String type) {
    switch (type) {
      case 'health':   return AppColors.danger;
      case 'warning':  return AppColors.warning;
      case 'success':  return AppColors.success;
      default:         return AppColors.primary;
    }
  }

  IconData _notifIcon(String type) {
    switch (type) {
      case 'health':   return Icons.medical_services_rounded;
      case 'warning':  return Icons.warning_amber_rounded;
      case 'success':  return Icons.check_circle_rounded;
      default:         return Icons.notifications_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PigProvider>();
    final sickPigs = pp.pigs
        .where((p) => p.status == PigStatus.sick || p.status == PigStatus.quarantine)
        .toList();

    // Detect new sick pigs in real-time
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForNewSickPigs(sickPigs));

    final criticalCount = sickPigs.length +
        _aiAlerts.where((a) => a.alertType == 'critical').length +
        _firestoreNotifs.where((n) => n['read'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        // ── Header ───────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 18, right: 18, bottom: 20,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
              if (criticalCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text('$criticalCount alert${criticalCount != 1 ? "s" : ""}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                ),
              GestureDetector(
                onTap: _refreshAll,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
                  child: _aiLoading || _newsLoading
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
            // AI summary bar
            if (sickPigs.isNotEmpty || _aiAlerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 17),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _aiAlerts.isEmpty
                        ? '${sickPigs.length} pig${sickPigs.length != 1 ? "s" : ""} currently need your attention.'
                        : 'AI detected ${_aiAlerts.length} alert${_aiAlerts.length != 1 ? "s" : ""} across your ${pp.totalPigs} pig${pp.totalPigs != 1 ? "s" : ""}.',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                  )),
                ]),
              ),
            ],
          ]),
        ),

        // ── Content ──────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [

                // ── Real-time Firestore notifications ────────────────────
                if (_firestoreNotifs.isNotEmpty) ...[
                  _sectionHeader(Icons.notifications_active_rounded, 'Live Notifications', AppColors.primary,
                      badge: _firestoreNotifs.where((n) => n['read'] == false).length),
                  ..._firestoreNotifs.map((n) {
                    final ts = (n['createdAt'] as dynamic);
                    DateTime dt;
                    try { dt = ts?.toDate() ?? DateTime.now(); } catch (_) { dt = DateTime.now(); }
                    return _NotifCard(
                      icon: _notifIcon(n['type'] ?? 'info'),
                      color: _notifColor(n['type'] ?? 'info'),
                      title: n['title'] ?? 'Notification',
                      body: n['message'] ?? '',
                      time: dt,
                      isUnread: n['read'] == false,
                      onTap: () {
                        if (n['read'] == false && n['id'] != null) {
                          FirestoreService.markNotificationRead(n['id']);
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                // ── AI Herd Alerts ───────────────────────────────────────
                _sectionHeader(Icons.smart_toy_rounded, 'AI Herd Alerts', AppColors.primary),
                if (_aiLoading)
                  _LoadingCard(label: 'AI is analysing your ${pp.totalPigs} pig${pp.totalPigs != 1 ? "s" : ""}...')
                else if (_aiAlerts.isEmpty)
                  _EmptyCard(icon: Icons.check_circle_rounded, color: AppColors.success, label: 'No AI alerts — herd looks healthy!')
                else
                  ..._aiAlerts.map((a) => _AiAlertCard(alert: a)),
                const SizedBox(height: 8),

                // ── Pig Health Alerts (real-time) ────────────────────────
                if (sickPigs.isNotEmpty) ...[
                  _sectionHeader(Icons.medical_services_rounded, 'Pig Health Alerts', AppColors.danger, badge: sickPigs.length),
                  ...sickPigs.map((p) => _NotifCard(
                    icon: p.status == PigStatus.sick ? Icons.medical_services_rounded : Icons.warning_amber_rounded,
                    color: p.status == PigStatus.sick ? AppColors.danger : AppColors.warning,
                    title: '${p.status.label}: ${p.name}',
                    body: '${p.name} (${p.tagId}) is ${p.status.label.toLowerCase()}. Check health records and take action immediately.',
                    time: p.updatedAt,
                    isUnread: true,
                    badge: p.status.label,
                    badgeColor: p.status.color,
                  )),
                  const SizedBox(height: 8),
                ],

                // ── News Alerts ──────────────────────────────────────────
                _sectionHeader(Icons.newspaper_rounded, 'News Alerts', AppColors.blue),
                if (_newsLoading)
                  const _LoadingCard(label: 'Fetching latest Kenya pig farming news...')
                else if (_newsAlerts.isEmpty)
                  const _EmptyCard(icon: Icons.newspaper_rounded, color: AppColors.blue, label: 'Pull to refresh for latest news.')
                else
                  ..._newsAlerts.take(4).map((n) => _NewsAlertCard(news: n)),
                const SizedBox(height: 8),

                // ── Farm Reminders ───────────────────────────────────────
                _sectionHeader(Icons.alarm_rounded, 'Farm Reminders', AppColors.warning),
                _NotifCard(
                  icon: Icons.restaurant_rounded, color: AppColors.warning,
                  title: 'Evening Feeding Reminder',
                  body: 'Evening feeding time is approaching. Ensure all pigs have fresh feed and water.',
                  time: DateTime.now().subtract(const Duration(hours: 2)), isUnread: false,
                ),
                _NotifCard(
                  icon: Icons.vaccines_rounded, color: AppColors.blue,
                  title: 'Vaccination Schedule Check',
                  body: 'Monthly FMD vaccination check is due. Review and update your vaccination records.',
                  time: DateTime.now().subtract(const Duration(days: 1)), isUnread: false,
                ),
                _NotifCard(
                  icon: Icons.monitor_weight_rounded, color: AppColors.primary,
                  title: 'Weight Recording Due',
                  body: 'It has been over 2 weeks since your last weight recording. Regular tracking improves accuracy.',
                  time: DateTime.now().subtract(const Duration(days: 2)), isUnread: false,
                ),
                const SizedBox(height: 8),

                // ── Farm Summary ─────────────────────────────────────────
                _sectionHeader(Icons.bar_chart_rounded, 'Farm Summary', AppColors.success),
                _FarmSummaryCard(pp: pp),
                const SizedBox(height: 8),

                // ── Community ────────────────────────────────────────────
                _sectionHeader(Icons.people_rounded, 'Community', const Color(0xFF8B5CF6)),
                _NotifCard(
                  icon: Icons.people_rounded, color: const Color(0xFF8B5CF6),
                  title: 'Community Alert',
                  body: 'A vet has posted an ASF update for your region. Check the community forum for the full advisory.',
                  time: DateTime.now().subtract(const Duration(days: 3)), isUnread: false,
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color, {int badge = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins', letterSpacing: 0.3)),
        if (badge > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Text('$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.2))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  AI ALERT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AiAlertCard extends StatelessWidget {
  final PigAlert alert;
  const _AiAlertCard({required this.alert});

  Color get _color {
    switch (alert.alertType) {
      case 'critical': return AppColors.danger;
      case 'warning':  return AppColors.warning;
      default:         return AppColors.blue;
    }
  }

  IconData get _icon {
    switch (alert.alertType) {
      case 'critical': return Icons.emergency_rounded;
      case 'warning':  return Icons.warning_amber_rounded;
      default:         return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final isCritical = alert.alertType == 'critical';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: isCritical ? 0.5 : 0.3), width: isCritical ? 1.5 : 1),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon, color: c, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(alert.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.smart_toy_rounded, size: 9, color: c),
                    const SizedBox(width: 3),
                    Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c, fontFamily: 'Poppins')),
                  ]),
                ),
              ]),
              const SizedBox(height: 3),
              Text(alert.pigName, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Text(alert.message, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.4)),
            ])),
          ]),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
          ),
          child: Row(children: [
            Icon(Icons.tips_and_updates_rounded, size: 13, color: c),
            const SizedBox(width: 6),
            Expanded(child: Text(alert.recommendation, style: TextStyle(fontSize: 11, color: c, fontFamily: 'Poppins', fontWeight: FontWeight.w600, height: 1.4))),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  NEWS ALERT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _NewsAlertCard extends StatelessWidget {
  final FarmNews news;
  const _NewsAlertCard({required this.news});

  Color get _color {
    switch (news.category) {
      case 'Health Alert': return AppColors.danger;
      case 'Market Price': return AppColors.success;
      case 'Breeding':     return const Color(0xFFEC4899);
      case 'Feed':         return const Color(0xFFF59E0B);
      default:             return AppColors.blue;
    }
  }

  IconData get _icon {
    switch (news.category) {
      case 'Health Alert': return Icons.medical_services_rounded;
      case 'Market Price': return Icons.trending_up_rounded;
      case 'Breeding':     return Icons.favorite_rounded;
      case 'Feed':         return Icons.restaurant_rounded;
      default:             return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: news.relevance == 'high'
            ? Border.all(color: c.withValues(alpha: 0.4), width: 1.5)
            : Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_icon, color: c, size: 21)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(news.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c, fontFamily: 'Poppins')),
              ),
              if (news.relevance == 'high') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('IMPORTANT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.danger, fontFamily: 'Poppins')),
                ),
              ],
              if (news.pubDate != null) ...[
                const Spacer(),
                Text(news.pubDate!, style: const TextStyle(fontSize: 9, color: AppColors.gray400, fontFamily: 'Poppins')),
              ],
            ]),
            const SizedBox(height: 6),
            Text(news.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
            if (news.source != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.source_rounded, size: 10, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(news.source!, style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins', fontStyle: FontStyle.italic)),
              ]),
            ],
            const SizedBox(height: 5),
            Text(news.summary, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.45)),
          ])),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STANDARD NOTIFICATION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  final DateTime time;
  final bool isUnread;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback? onTap;

  const _NotifCard({
    required this.icon, required this.color, required this.title,
    required this.body, required this.time, required this.isUnread,
    this.badge, this.badgeColor, this.onTap,
  });

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1)  return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    if (d.inDays < 7)     return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
              : Border.all(color: AppColors.gray200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'))),
                if (isUnread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.4)),
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 11, color: AppColors.gray400),
                const SizedBox(width: 4),
                Text(_ago(time), style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: (badgeColor ?? color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor ?? color, fontFamily: 'Poppins')),
                  ),
                ],
              ]),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FARM SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _FarmSummaryCard extends StatelessWidget {
  final PigProvider pp;
  const _FarmSummaryCard({required this.pp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        const Row(children: [
          Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Your Farm Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _summaryChip('${pp.totalPigs}', 'Active Pigs', Icons.pets_rounded),
          const SizedBox(width: 8),
          _summaryChip('${pp.healthyCount}', 'Healthy', Icons.favorite_rounded),
          const SizedBox(width: 8),
          _summaryChip('${pp.sickCount + pp.quarantineCount}', 'Attention', Icons.warning_amber_rounded),
        ]),
      ]),
    );
  }

  Widget _summaryChip(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, size: 17, color: Colors.white70),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.white70, fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final String label;
  const _LoadingCard({this.label = 'Loading...'});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2))),
    child: Row(children: [
      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins', fontStyle: FontStyle.italic))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _EmptyCard({required this.icon, required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins'))),
    ]),
  );
}