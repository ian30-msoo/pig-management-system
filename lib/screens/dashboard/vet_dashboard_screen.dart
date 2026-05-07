// lib/screens/dashboard/vet_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../models/pig_model.dart';
import '../../widgets/common/widgets.dart';
import '../ai/ai_screen.dart';
import '../notifications/notifications_screen.dart';
import '../community/community_screen.dart';
import '../main/main_scaffold.dart';
import '../vet/vet_cases_screen.dart';
import '../vet/vet_finance_screen.dart';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});
  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  bool _refreshing = false;

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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌤️';
    if (h < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  String _todayDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  static final _diseaseAlerts = [
    {'title': 'PRRS Outbreak Risk', 'desc': "High risk in Kiambu, Murang'a counties", 'level': 'HIGH', 'icon': Icons.warning_rounded, 'color': AppColors.danger},
    {'title': 'ASF Monitoring', 'desc': 'African Swine Fever — surveillance active', 'level': 'MEDIUM', 'icon': Icons.visibility_rounded, 'color': AppColors.warning},
    {'title': 'FMD Vaccination Drive', 'desc': 'Foot & Mouth Disease campaign this month', 'level': 'INFO', 'icon': Icons.vaccines_rounded, 'color': AppColors.blue},
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final pigs = context.watch<PigProvider>();
    final user = auth.user;

    final totalCases    = pigs.totalPigs;
    final openCases     = pigs.sickCount + pigs.quarantineCount;
    final resolvedCases = pigs.healthyCount;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: CustomScrollView(slivers: [

        // ── Header ────────────────────────────────────────────────────────
        SliverToBoxAdapter(child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            child: Column(children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting(), style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Poppins')),
                  Text('Dr. ${user?.firstName ?? ""}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      'Veterinarian · ${user?.displayCounty.isNotEmpty == true ? user!.displayCounty : "Kenya"}',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    ),
                  ),
                ])),
                // ✅ Refresh button
                GestureDetector(
                  onTap: _refresh,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                    child: _refreshing
                        ? const Padding(padding: EdgeInsets.all(11), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                _HeaderIconBtn(icon: Icons.notifications_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                const SizedBox(width: 8),
                _HeaderIconBtn(icon: Icons.menu_rounded, onTap: () => mainScaffoldKey.currentState?.openDrawer()),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(_todayDate(), style: const TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: openCases > 0 ? AppColors.danger : AppColors.success, borderRadius: BorderRadius.circular(20)),
                    child: Text('$openCases open case${openCases != 1 ? "s" : ""}', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                  ),
                ]),
              ),
            ]),
          )),
        )),

        // ── Body ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // AI Banner
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen())),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.smart_toy_rounded, size: 22, color: Colors.white)),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('AI Diagnostic Assistant', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                    SizedBox(height: 2),
                    Text('Analyze symptoms and get AI-powered diagnoses', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), height: 1.4, fontFamily: 'Poppins')),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            LayoutBuilder(builder: (ctx, constraints) {
              final w = (constraints.maxWidth - 10) / 2;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                SizedBox(width: w, child: _VetStatCard(label: 'Total Pigs', value: '$totalCases', icon: Icons.folder_open_rounded, color: AppColors.primary, bgColor: AppColors.primaryBg)),
                SizedBox(width: w, child: _VetStatCard(label: 'Open Cases', value: '$openCases', icon: Icons.pending_rounded, color: AppColors.warning, bgColor: AppColors.warningBg)),
                SizedBox(width: w, child: _VetStatCard(label: 'Healthy', value: '$resolvedCases', icon: Icons.check_circle_rounded, color: AppColors.success, bgColor: AppColors.successBg)),
                SizedBox(width: w, child: _VetStatCard(label: 'Vaccinations', value: '${pigs.totalPigs > 0 ? (pigs.totalPigs * 0.8).floor() : 0}', icon: Icons.vaccines_rounded, color: AppColors.blue, bgColor: AppColors.blueBg, badge: 'This month')),
              ]);
            }),
            const SizedBox(height: 18),

            // Quick Actions
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 10),
            Row(children: [
              _QuickAction(icon: Icons.add_circle_rounded, label: 'New Case', color: AppColors.primary, bg: AppColors.primaryBg,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VetCasesScreen()))),
              const SizedBox(width: 8),
              _QuickAction(icon: Icons.account_balance_wallet_rounded, label: 'Charge', color: AppColors.success, bg: AppColors.successBg,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VetFinanceScreen()))),
              const SizedBox(width: 8),
              _QuickAction(icon: Icons.smart_toy_rounded, label: 'AI Diagnose', color: AppColors.warning, bg: AppColors.warningBg,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIScreen()))),
              const SizedBox(width: 8),
              _QuickAction(icon: Icons.people_rounded, label: 'Farmers', color: AppColors.blue, bg: AppColors.blueBg,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()))),
            ]),
            const SizedBox(height: 18),

            // Disease Alerts
            const SectionHeader(title: 'Disease Alerts'),
            const SizedBox(height: 10),
            ..._diseaseAlerts.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: alert['color'] as Color, borderRadius: BorderRadius.circular(13)), child: Icon(alert['icon'] as IconData, color: Colors.white, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(alert['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                  const SizedBox(height: 2),
                  Text(alert['desc'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins', height: 1.3)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (alert['color'] as Color).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(alert['level'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: alert['color'] as Color, fontFamily: 'Poppins')),
                ),
              ]),
            )),
            const SizedBox(height: 18),

            // Recent Cases
            SectionHeader(title: 'Recent Cases', actionLabel: 'View All', onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VetCasesScreen()))),
            const SizedBox(height: 10),
            if (pigs.activePigs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(child: Text('No pigs registered yet', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins'))),
              )
            else
              ...pigs.activePigs.take(4).map((p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                child: Row(children: [
                  p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(p.imageUrl!, width: 40, height: 40, fit: BoxFit.cover))
                      : Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: p.status == PigStatus.healthy ? AppColors.successBg : AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(p.status == PigStatus.healthy ? Icons.check_circle_rounded : Icons.medical_services_rounded, size: 18, color: p.status == PigStatus.healthy ? AppColors.success : AppColors.danger),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${p.name} · ${p.tagId}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                    Text('${p.breed}${p.location != null ? " · ${p.location}" : ""}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.status == PigStatus.healthy ? AppColors.successBg : p.status == PigStatus.sick ? AppColors.dangerBg : AppColors.warningBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(p.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.status == PigStatus.healthy ? AppColors.success : p.status == PigStatus.sick ? AppColors.danger : AppColors.warning, fontFamily: 'Poppins')),
                  ),
                ]),
              )),
          ])),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _VetStatCard extends StatelessWidget {
  final String label, value; final IconData icon; final Color color, bgColor; final String? badge;
  const _VetStatCard({required this.label, required this.value, required this.icon, required this.color, required this.bgColor, this.badge});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
        if (badge != null) ...[
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins'))),
        ],
      ]),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.dark, fontFamily: 'Poppins')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
    ]),
  );
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 20)),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color, bg; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color)),
        const SizedBox(height: 6),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
      ]),
    ),
  ));
}