// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../models/pig_model.dart';
import '../../models/models.dart';
import '../pigs/pigs_screen.dart';
import '../feeding/feeding_screen.dart';
import '../health/health_screen.dart';
import '../breeding/breeding_screen.dart';
import '../finance/finance_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../main/main_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  String _query     = '';
  bool _refreshing  = false;

  @override
  void initState() {
    super.initState();
    // ✅ Force finance data refresh on every screen visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<app_auth.AuthProvider>().uid;
      if (uid != null) {
        context.read<FinanceProvider>().forceInit(uid);
      }
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final uid = context.read<app_auth.AuthProvider>().uid;
    if (uid != null) {
      context.read<FinanceProvider>().forceInit(uid);
      context.read<PigProvider>().init();
    }
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<app_auth.AuthProvider>();
    final pigs    = context.watch<PigProvider>();
    final finance = context.watch<FinanceProvider>();
    final user    = auth.user;
    final alerts  = pigs.getAlerts();
    final mq      = MediaQuery.of(context);
    final isSmall = mq.size.width < 360;
    final top     = mq.padding.top;

    final isSearching = _query.isNotEmpty;

    return ColoredBox(
      color: const Color(0xFFF5F6FA),
      child: Column(children: [
        _DashboardHeader(
          user: user,
          alertCount: alerts.length,
          isSmall: isSmall,
          statusBarHeight: top,
          searchCtrl: _searchCtrl,
          onSearch: (v) => setState(() => _query = v.toLowerCase().trim()),
          refreshing: _refreshing,
          onRefresh: _refresh,
        ),
        Expanded(
          child: isSearching
              ? _GlobalSearchResults(
            query: _query,
            pigs: pigs,
            finance: finance,
            onClear: _clearSearch,
          )
              : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(isSmall ? 14 : 16, 20, isSmall ? 14 : 16, 110),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Quick Actions ──────────────────────────────────
                const _RowTitle(title: 'Quick Actions'),
                const SizedBox(height: 12),
                _QuickActionsGrid(isSmall: isSmall),
                const SizedBox(height: 24),

                // ── Overview ───────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const _RowTitle(title: 'Overview'),
                  GestureDetector(
                    onTap: _refresh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _refreshing
                          ? const SizedBox(width: 46, height: 18,
                          child: Center(child: SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))))
                          : const Row(children: [
                        Icon(Icons.refresh_rounded, size: 13, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Refresh', style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w600, color: AppColors.primary,
                            fontFamily: 'Poppins')),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _OverviewGrid(pigs: pigs, finance: finance, isSmall: isSmall),
                const SizedBox(height: 24),

                // ── My Pigs ────────────────────────────────────────
                _TitleWithAction(
                  title: 'My Pigs',
                  actionLabel: 'See All',
                  onAction: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PigsScreen())),
                ),
                const SizedBox(height: 12),
                _PigsHorizontalList(pigs: pigs),
                const SizedBox(height: 24),

                // ── Breeding & Maturity ────────────────────────────
                _TitleWithAction(
                  title: 'Breeding & Maturity',
                  actionLabel: 'View All',
                  onAction: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BreedingScreen())),
                ),
                const SizedBox(height: 12),
                _BreedingBanner(),
                const SizedBox(height: 24),

                // ── Health Alerts ──────────────────────────────────
                _TitleWithAction(
                  title: 'Health Alerts',
                  actionLabel: 'View All',
                  onAction: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HealthScreen())),
                ),
                const SizedBox(height: 12),
                _HealthAlerts(alerts: alerts),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  GLOBAL SEARCH RESULTS
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalSearchResults extends StatelessWidget {
  final String query;
  final PigProvider pigs;
  final FinanceProvider finance;
  final VoidCallback onClear;

  const _GlobalSearchResults({
    required this.query,
    required this.pigs,
    required this.finance,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final matchedPigs = pigs.pigs.where((p) =>
    p.name.toLowerCase().contains(query) ||
        p.tagId.toLowerCase().contains(query) ||
        p.breed.toLowerCase().contains(query) ||
        p.status.label.toLowerCase().contains(query)).toList();

    final matchedAlerts = pigs.getAlerts().where((p) =>
    p.name.toLowerCase().contains(query) ||
        p.tagId.toLowerCase().contains(query) ||
        p.status.label.toLowerCase().contains(query)).toList();

    final matchedTx = finance.transactions.where((t) =>
    t.description.toLowerCase().contains(query) ||
        t.category.toLowerCase().contains(query) ||
        t.type.name.toLowerCase().contains(query)).toList();

    final hasResults = matchedPigs.isNotEmpty || matchedAlerts.isNotEmpty || matchedTx.isNotEmpty;

    if (!hasResults) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No results for "$query"',
              style: const TextStyle(fontSize: 14, color: AppColors.gray400,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onClear,
            child: const Text('Clear search',
                style: TextStyle(fontSize: 12, color: AppColors.primary,
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        if (matchedPigs.isNotEmpty) ...[
          _SearchSectionLabel(
              icon: Icons.pets_rounded, label: 'Pigs', count: matchedPigs.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PigsScreen()))),
          const SizedBox(height: 8),
          ...matchedPigs.take(5).map((p) => _PigResultTile(pig: p)),
          const SizedBox(height: 16),
        ],
        if (matchedAlerts.isNotEmpty) ...[
          _SearchSectionLabel(
              icon: Icons.health_and_safety_rounded, label: 'Health Alerts', count: matchedAlerts.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen()))),
          const SizedBox(height: 8),
          ...matchedAlerts.take(5).map((p) => _AlertResultTile(pig: p)),
          const SizedBox(height: 16),
        ],
        if (matchedTx.isNotEmpty) ...[
          _SearchSectionLabel(
              icon: Icons.account_balance_wallet_rounded, label: 'Financial Records', count: matchedTx.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen()))),
          const SizedBox(height: 8),
          ...matchedTx.take(5).map((t) => _TxResultTile(tx: t)),
        ],
      ],
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  final IconData icon; final String label; final int count; final VoidCallback onTap;
  const _SearchSectionLabel({required this.icon, required this.label, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins')),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins')),
        ),
      ]),
      GestureDetector(onTap: onTap, child: const Text('See all →', style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins'))),
    ]);
  }
}

class _PigResultTile extends StatelessWidget {
  final PigModel pig;
  const _PigResultTile({required this.pig});
  @override
  Widget build(BuildContext context) {
    final isHealthy = pig.status == PigStatus.healthy;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PigsScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          pig.imageUrl != null && pig.imageUrl!.isNotEmpty
              ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(pig.imageUrl!, width: 42, height: 42, fit: BoxFit.cover))
              : Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(pig.stageEmoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pig.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            const SizedBox(height: 2),
            Text('${pig.tagId} · ${pig.breed} · ${pig.weight.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: isHealthy ? AppColors.successBg : AppColors.dangerBg, borderRadius: BorderRadius.circular(20)),
            child: Text(pig.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isHealthy ? AppColors.success : AppColors.danger, fontFamily: 'Poppins')),
          ),
        ]),
      ),
    );
  }
}

class _AlertResultTile extends StatelessWidget {
  final PigModel pig;
  const _AlertResultTile({required this.pig});
  @override
  Widget build(BuildContext context) {
    final isSick = pig.status == PigStatus.sick;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: isSick ? AppColors.dangerBg : AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(isSick ? Icons.healing_outlined : Icons.warning_amber_rounded, size: 20, color: isSick ? AppColors.danger : AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pig.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            const SizedBox(height: 2),
            Text('${pig.status.label} · Tag: ${pig.tagId}', style: TextStyle(fontSize: 11, color: isSick ? AppColors.danger : AppColors.warning, fontFamily: 'Poppins')),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 18),
        ]),
      ),
    );
  }
}

class _TxResultTile extends StatelessWidget {
  final TransactionModel tx;
  const _TxResultTile({required this.tx});
  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TransactionType.expense;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: isExpense ? AppColors.dangerBg : AppColors.successBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(isExpense ? Icons.trending_down_rounded : Icons.trending_up_rounded, size: 20, color: isExpense ? AppColors.danger : AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            const SizedBox(height: 2),
            Text('${tx.category} · ${tx.date.day}/${tx.date.month}/${tx.date.year}', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
          ])),
          Text('${isExpense ? "-" : "+"}KSh ${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isExpense ? AppColors.danger : AppColors.success, fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final dynamic user;
  final int alertCount;
  final bool isSmall;
  final double statusBarHeight;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final bool refreshing;
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.user,
    required this.alertCount,
    required this.isSmall,
    required this.statusBarHeight,
    required this.searchCtrl,
    required this.onSearch,
    required this.refreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: statusBarHeight + 12,
        left: isSmall ? 14 : 18,
        right: isSmall ? 14 : 18,
        bottom: 22,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
              ),
              child: user?.photoUrl != null && (user!.photoUrl as String).isNotEmpty
                  ? ClipOval(child: Image.network(user.photoUrl as String, fit: BoxFit.cover))
                  : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(_greeting(), style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Poppins')),
              Text(user?.firstName ?? 'Farmer', style: TextStyle(fontSize: isSmall ? 17 : 19, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins', height: 1.2)),
            ]),
          ),
          // ✅ Refresh button in header
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2)),
              child: refreshing
                  ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          _HeaderBtn(
            icon: Icons.notifications_outlined,
            badge: alertCount > 0 ? alertCount : null,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(width: 8),
          _HeaderBtn(icon: Icons.menu_rounded, onTap: () => mainScaffoldKey.currentState?.openDrawer()),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.place_rounded, size: 13, color: Colors.white70),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${user?.displayRole ?? "Farmer"}  ·  ${(user?.displayCounty?.isNotEmpty == true) ? user!.displayCounty : "Kenya"}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Poppins', fontWeight: FontWeight.w400),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, size: 18, color: Colors.white70),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearch,
                style: TextStyle(fontSize: isSmall ? 12 : 13, color: Colors.white, fontFamily: 'Poppins'),
                decoration: InputDecoration(
                  hintText: 'Search pigs, records, alerts...',
                  hintStyle: TextStyle(fontSize: isSmall ? 12 : 13, color: Colors.white54, fontFamily: 'Poppins'),
                  border: InputBorder.none, isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                cursorColor: Colors.white,
              ),
            ),
            if (searchCtrl.text.isNotEmpty)
              GestureDetector(
                onTap: () { searchCtrl.clear(); onSearch(''); },
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
              ),
          ]),
        ),
      ]),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final int? badge;
  const _HeaderBtn({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -3, right: -3,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 1.5)),
              child: Center(child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800))),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROW TITLE
// ─────────────────────────────────────────────────────────────────────────────

class _RowTitle extends StatelessWidget {
  final String title;
  const _RowTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins'));
}

// ─────────────────────────────────────────────────────────────────────────────
//  TITLE WITH ACTION
// ─────────────────────────────────────────────────────────────────────────────

class _TitleWithAction extends StatelessWidget {
  final String title, actionLabel; final VoidCallback onAction;
  const _TitleWithAction({required this.title, required this.actionLabel, required this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
      GestureDetector(onTap: onAction, child: const Text('View all →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray400, fontFamily: 'Poppins'))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUICK ACTIONS
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final bool isSmall;
  const _QuickActionsGrid({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QAItem(icon: Icons.add_circle_outline_rounded, label: 'Add Pig', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PigsScreen()))),
      _QAItem(icon: Icons.grid_view_rounded, label: 'All Pigs', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PigsScreen()))),
      _QAItem(icon: Icons.rice_bowl_outlined, label: 'Feeding', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedingScreen()))),
      _QAItem(icon: Icons.monitor_heart_outlined, label: 'Health', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen()))),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final idx = e.key; final item = e.value;
        return Expanded(child: Padding(
          padding: EdgeInsets.only(right: idx < items.length - 1 ? 10 : 0),
          child: _QuickActionTile(item: item, isSmall: isSmall),
        ));
      }).toList(),
    );
  }
}

class _QAItem {
  final IconData icon; final String label; final VoidCallback onTap;
  const _QAItem({required this.icon, required this.label, required this.onTap});
}

class _QuickActionTile extends StatelessWidget {
  final _QAItem item; final bool isSmall;
  const _QuickActionTile({required this.item, required this.isSmall});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 14 : 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon, size: isSmall ? 22 : 24, color: AppColors.primary),
          const SizedBox(height: 7),
          Text(item.label, textAlign: TextAlign.center, style: TextStyle(fontSize: isSmall ? 10 : 11, fontWeight: FontWeight.w600, color: const Color(0xFF3A3A4A), fontFamily: 'Poppins')),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERVIEW GRID
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewGrid extends StatelessWidget {
  final PigProvider pigs; final FinanceProvider finance; final bool isSmall;
  const _OverviewGrid({required this.pigs, required this.finance, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    final items = [
      _OvItem(label: 'Total Pigs',    value: '${pigs.totalPigs}',  icon: Icons.pets_rounded, iconColor: AppColors.primary, iconBg: AppColors.primaryBg),
      _OvItem(label: 'Health Alerts', value: '${pigs.sickCount + pigs.quarantineCount}', icon: Icons.health_and_safety_rounded, iconColor: AppColors.danger, iconBg: AppColors.dangerBg),
      _OvItem(label: 'Feed Due',      value: '${pigs.activePigs.length > 3 ? 5 : pigs.activePigs.length}', icon: Icons.rice_bowl_rounded, iconColor: AppColors.warning, iconBg: AppColors.warningBg),
      _OvItem(label: 'Revenue',       value: 'KSh ${(finance.totalIncome / 1000).toStringAsFixed(0)}K', icon: Icons.payments_rounded, iconColor: AppColors.success, iconBg: AppColors.successBg),
    ];

    return LayoutBuilder(builder: (_, box) {
      final w = (box.maxWidth - 12) / 2;
      return Wrap(spacing: 12, runSpacing: 12,
          children: items.map((item) => SizedBox(width: w, child: _OverviewCard(item: item, isSmall: isSmall))).toList());
    });
  }
}

class _OvItem {
  final String label, value; final IconData icon; final Color iconColor, iconBg;
  const _OvItem({required this.label, required this.value, required this.icon, required this.iconColor, required this.iconBg});
}

class _OverviewCard extends StatelessWidget {
  final _OvItem item; final bool isSmall;
  const _OverviewCard({required this.item, required this.isSmall});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: item.iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(item.icon, size: 18, color: item.iconColor)),
        const SizedBox(height: 14),
        Text(item.value, style: TextStyle(fontSize: isSmall ? 20 : 22, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E), fontFamily: 'Poppins', height: 1.1)),
        const SizedBox(height: 3),
        Text(item.label, style: TextStyle(fontSize: isSmall ? 11 : 12, color: AppColors.gray400, fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PIGS HORIZONTAL LIST
// ─────────────────────────────────────────────────────────────────────────────

class _PigsHorizontalList extends StatelessWidget {
  final PigProvider pigs;
  const _PigsHorizontalList({required this.pigs});

  @override
  Widget build(BuildContext context) {
    if (pigs.activePigs.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.pets_rounded, size: 28, color: Colors.grey.shade300),
          const SizedBox(height: 6),
          Text('No pigs added yet', style: TextStyle(color: Colors.grey.shade400, fontFamily: 'Poppins', fontSize: 13)),
        ])),
      );
    }

    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pigs.activePigs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final p = pigs.activePigs[i];
          final isHealthy = p.status == PigStatus.healthy;
          return GestureDetector(
            onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PigsScreen())),
            child: Container(
              width: 144, padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(p.imageUrl!, width: 40, height: 40, fit: BoxFit.cover))
                      : Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(p.stageEmoji, style: const TextStyle(fontSize: 20)))),
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isHealthy ? AppColors.success : AppColors.danger)),
                ]),
                const SizedBox(height: 10),
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text('${p.tagId} · ${p.breed}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), fontFamily: 'Poppins')),
                Text('${p.weight.toStringAsFixed(0)} kg · ${p.ageLabel}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF757575), fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: isHealthy ? AppColors.successBg : AppColors.dangerBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(p.status.label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: isHealthy ? AppColors.success : AppColors.danger, fontFamily: 'Poppins')),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BREEDING BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _BreedingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreedingScreen())),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.favorite_rounded, size: 22, color: Color(0xFFE91E63))),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Breeding & Maturity Tracker', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            SizedBox(height: 3),
            Text('Track sow cycles, breeding dates & piglet records', style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEALTH ALERTS
// ─────────────────────────────────────────────────────────────────────────────

class _HealthAlerts extends StatelessWidget {
  final List<dynamic> alerts;
  const _HealthAlerts({required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle_outline_rounded, size: 22, color: AppColors.success)),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('All pigs are healthy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
            SizedBox(height: 2),
            Text('No active health concerns right now.', style: TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
          ])),
        ]),
      );
    }

    return Column(
      children: alerts.take(3).map<Widget>((dynamic raw) {
        final PigModel p = raw as PigModel;
        final isSick = p.status == PigStatus.sick;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthScreen())),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(children: [
              Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: isSick ? AppColors.dangerBg : AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isSick ? Icons.healing_outlined : Icons.warning_amber_rounded, size: 20, color: isSick ? AppColors.danger : AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text('${p.status.label} · Tag: ${p.tagId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isSick ? AppColors.danger : AppColors.warning, fontFamily: 'Poppins')),
              ])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 20),
            ]),
          ),
        );
      }).toList(),
    );
  }
}