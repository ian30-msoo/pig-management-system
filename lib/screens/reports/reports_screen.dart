// lib/screens/reports/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../models/pig_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<HealthRecord> _allHealth = [];
  bool _healthLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadHealth();
  }

  /// Load health records from ALL pigs in one go
  Future<void> _loadHealth() async {
    if (!mounted) return;
    setState(() => _healthLoading = true);
    final provider = context.read<PigProvider>();
    final pigs = provider.allPigs;
    if (pigs.isEmpty) { if (mounted) setState(() => _healthLoading = false); return; }
    try {
      final results = await Future.wait(pigs.map((p) => provider.getPigHealth(p.id)));
      final all = results.expand((list) => list).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() { _allHealth = all; _healthLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _healthLoading = false);
    }
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white)),
                ),
              const Expanded(child: Text('Reports & Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
              GestureDetector(
                onTap: _loadHealth,
                child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabs,
              labelColor: Colors.white, unselectedLabelColor: Colors.white54,
              indicatorColor: Colors.white, indicatorWeight: 3,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [Tab(text: 'Finance'), Tab(text: 'Pigs'), Tab(text: 'Health')],
            ),
          ]),
        ),
        Expanded(child: TabBarView(
          controller: _tabs,
          children: [
            _FinanceReport(),
            _PigReport(onRefresh: _loadHealth),
            _HealthReport(health: _allHealth, loading: _healthLoading, onRefresh: _loadHealth),
          ],
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FINANCE REPORT
// ─────────────────────────────────────────────────────────────────────────────

class _FinanceReport extends StatelessWidget {
  const _FinanceReport();

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final monthlyData = _monthlyData(finance.transactions);
    final categories = _categoryBreakdown(finance.transactions);
    final pigsales = finance.transactions.where((t) => t.type == TransactionType.sale && t.pigId != null).length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary cards
          Row(children: [
            Expanded(child: _MiniCard('Total Revenue', 'KSh ${_fmt(finance.totalIncome)}', AppColors.success, Icons.trending_up_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MiniCard('Total Expenses', 'KSh ${_fmt(finance.totalExpenses)}', AppColors.danger, Icons.trending_down_rounded)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MiniCard('Net Profit', 'KSh ${_fmt(finance.profit)}', finance.profit >= 0 ? AppColors.blue : AppColors.danger, Icons.account_balance_wallet_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MiniCard('Pig Sales', '$pigsales pigs sold', AppColors.primary, Icons.sell_rounded)),
          ]),
          const SizedBox(height: 16),

          // Monthly Income vs Expenses bar chart
          _SectionHeader('Monthly Income vs Expenses'),
          Container(
            height: 220, padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
            child: monthlyData.every((d) => d[1] == 0 && d[2] == 0)
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.gray200), SizedBox(height: 8), Text('No transactions yet', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins'))]))
                : Column(children: [
              // Legend
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _LegendDot(AppColors.success, 'Income'),
                const SizedBox(width: 16),
                _LegendDot(AppColors.danger, 'Expenses'),
              ]),
              const SizedBox(height: 8),
              Expanded(child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: monthlyData.map((d) => d[1] > d[2] ? d[1] : d[2]).fold(0.0, (a, b) => a > b ? a : b) * 1.25 + 1,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem('KSh ${_fmt(rod.toY)}', const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= monthlyData.length) return const SizedBox();
                    return Text(_monthLabel(monthlyData[i][0].toInt()), style: const TextStyle(fontSize: 9, fontFamily: 'Poppins', color: AppColors.gray400));
                  })),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: null,
                    getDrawingHorizontalLine: (v) => FlLine(color: AppColors.gray200, strokeWidth: 0.5, dashArray: [4, 4])),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(monthlyData.length, (i) => BarChartGroupData(x: i, groupVertically: false, barRods: [
                  BarChartRodData(toY: monthlyData[i][1], color: AppColors.success, width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  BarChartRodData(toY: monthlyData[i][2], color: AppColors.danger,  width: 9, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ])),
              ))),
            ]),
          ),
          const SizedBox(height: 16),

          // This month breakdown
          _SectionHeader('This Month'),
          Row(children: [
            Expanded(child: _MiniCard('Sales', 'KSh ${_fmt(finance.monthlyIncome)}', AppColors.success, Icons.trending_up_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MiniCard('Expenses', 'KSh ${_fmt(finance.monthlyExpenses)}', AppColors.danger, Icons.trending_down_rounded)),
          ]),
          const SizedBox(height: 16),

          // Category breakdown
          if (categories.isNotEmpty) ...[
            _SectionHeader('Top Categories'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
              child: Column(children: categories.map((c) => _CategoryRow(label: c.$1, amount: 'KSh ${_fmt(c.$2)}', pct: c.$3)).toList()),
            ),
          ],

          // Recent transactions summary
          const SizedBox(height: 16),
          _SectionHeader('Recent Activity'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
            child: finance.transactions.isEmpty
                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No transactions recorded yet', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins'))))
                : Column(children: finance.transactions.take(5).map((t) {
              final isExp = t.type == TransactionType.expense;
              return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: isExp ? AppColors.dangerBg : AppColors.successBg, borderRadius: BorderRadius.circular(10)), child: Icon(isExp ? Icons.trending_down_rounded : Icons.trending_up_rounded, size: 18, color: isExp ? AppColors.danger : AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                  Text('${t.date.day}/${t.date.month}/${t.date.year} · ${t.category}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
                ])),
                Text('${isExp ? "-" : "+"}KSh ${t.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isExp ? AppColors.danger : AppColors.success, fontFamily: 'Poppins')),
              ]));
            }).toList()),
          ),
        ],
      ),
    );
  }

  List<List<double>> _monthlyData(List<TransactionModel> txs) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      final inc  = txs.where((t) => t.date.month == month.month && t.date.year == month.year && t.type != TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
      final exp  = txs.where((t) => t.date.month == month.month && t.date.year == month.year && t.type == TransactionType.expense).fold(0.0, (s, t) => s + t.amount);
      return [month.month.toDouble(), inc, exp];
    });
  }

  String _monthLabel(int month) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][(month - 1).clamp(0, 11)];

  List<(String, double, double)> _categoryBreakdown(List<TransactionModel> txs) {
    final cats = <String, double>{};
    final total = txs.fold(0.0, (s, t) => s + t.amount);
    for (final t in txs) { cats[t.category] = (cats[t.category] ?? 0) + t.amount; }
    if (cats.isEmpty) return [];
    return (cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5).map((e) => (e.key, e.value, total > 0 ? e.value / total : 0.0)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PIG REPORT
// ─────────────────────────────────────────────────────────────────────────────

class _PigReport extends StatelessWidget {
  final VoidCallback onRefresh;
  const _PigReport({required this.onRefresh});

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  @override
  Widget build(BuildContext context) {
    final pigs = context.watch<PigProvider>();
    final all  = pigs.allPigs;

    if (all.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.pets_rounded, size: 64, color: AppColors.gray200), const SizedBox(height: 12),
      const Text('No pig data yet', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins', fontSize: 15)),
    ]));

    final byBreed  = <String, int>{};
    final byStatus = <String, int>{};
    final byStage  = <String, int>{};
    final byGender = <String, int>{'Male': 0, 'Female': 0};
    double totalWeight = 0;
    for (final p in all) {
      byBreed[p.breed]         = (byBreed[p.breed] ?? 0) + 1;
      byStatus[p.status.label] = (byStatus[p.status.label] ?? 0) + 1;
      byStage[p.stage]         = (byStage[p.stage] ?? 0) + 1;
      byGender[p.gender == PigGender.male ? 'Male' : 'Female'] = (byGender[p.gender == PigGender.male ? 'Male' : 'Female'] ?? 0) + 1;
      totalWeight += p.weight;
    }
    final avgWeight = all.isEmpty ? 0.0 : totalWeight / all.length;
    final heaviest = all.reduce((a, b) => a.weight > b.weight ? a : b);
    final lightest = all.reduce((a, b) => a.weight < b.weight ? a : b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Summary
        Row(children: [
          Expanded(child: _MiniCard('Total Pigs', '${pigs.totalPigs}', AppColors.primary, Icons.pets_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard('Sold', '${pigs.soldCount}', AppColors.gray400, Icons.sell_rounded)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MiniCard('Healthy', '${pigs.healthyCount}', AppColors.success, Icons.favorite_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard('Sick / Quarantine', '${pigs.sickCount + pigs.quarantineCount}', AppColors.danger, Icons.medical_services_rounded)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MiniCard('Avg Weight', '${avgWeight.toStringAsFixed(1)} kg', AppColors.blue, Icons.monitor_weight_rounded)),
          const SizedBox(width: 10),
          Expanded(child: _MiniCard('Total Weight', '${totalWeight.toStringAsFixed(0)} kg', AppColors.primary, Icons.scale_rounded)),
        ]),
        const SizedBox(height: 16),

        // Weight highlights
        _SectionHeader('Weight Highlights'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
          child: Column(children: [
            _InfoRow2(Icons.arrow_upward_rounded, AppColors.success, 'Heaviest', '${heaviest.name} — ${heaviest.weight.toStringAsFixed(1)} kg'),
            const SizedBox(height: 8),
            _InfoRow2(Icons.arrow_downward_rounded, AppColors.warning, 'Lightest', '${lightest.name} — ${lightest.weight.toStringAsFixed(1)} kg'),
            const SizedBox(height: 8),
            _InfoRow2(Icons.calculate_rounded, AppColors.blue, 'Average', '${avgWeight.toStringAsFixed(1)} kg'),
          ]),
        ),
        const SizedBox(height: 16),

        // Gender breakdown
        _SectionHeader('Gender Distribution'),
        _PieSection(byGender),
        const SizedBox(height: 16),

        // Status breakdown
        _SectionHeader('Status Breakdown'),
        _PieSection(byStatus),
        const SizedBox(height: 16),

        // By breed
        _SectionHeader('Pigs by Breed'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
          child: Column(children: (byBreed.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => _CategoryRow(label: e.key, amount: '${e.value} pig${e.value != 1 ? "s" : ""}', pct: all.isEmpty ? 0 : e.value / all.length)).toList()),
        ),
        const SizedBox(height: 16),

        // By stage
        _SectionHeader('Pigs by Stage'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
          child: Column(children: (byStage.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => _CategoryRow(label: e.key, amount: '${e.value} pig${e.value != 1 ? "s" : ""}', pct: all.isEmpty ? 0 : e.value / all.length)).toList()),
        ),

        // Individual list
        const SizedBox(height: 16),
        _SectionHeader('All Pigs (${all.length})'),
        ...all.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: p.status.bgColor, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(p.stageEmoji, style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
              Text('${p.tagId} · ${p.breed} · ${p.ageLabel}', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${p.weight.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary, fontFamily: 'Poppins')),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: p.status.bgColor, borderRadius: BorderRadius.circular(10)), child: Text(p.status.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: p.status.color, fontFamily: 'Poppins'))),
            ]),
          ]),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEALTH REPORT  — ✅ loads real health data from all pigs
// ─────────────────────────────────────────────────────────────────────────────

class _HealthReport extends StatelessWidget {
  final List<HealthRecord> health;
  final bool loading;
  final VoidCallback onRefresh;
  const _HealthReport({required this.health, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final pigs = context.watch<PigProvider>();

    if (loading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppColors.primary), SizedBox(height: 14),
      Text('Loading health records...', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins', fontSize: 13)),
    ]));

    final byType   = <String, int>{};
    final byStatus = <String, int>{};
    for (final h in health) {
      byType[h.type]     = (byType[h.type] ?? 0) + 1;
      byStatus[h.status] = (byStatus[h.status] ?? 0) + 1;
    }

    final vaccinations = health.where((h) => h.type == 'Vaccination').length;
    final treatments   = health.where((h) => h.type == 'Treatment').length;
    final dewormings   = health.where((h) => h.type == 'Deworming').length;
    final checkups     = health.where((h) => h.type == 'Checkup').length;
    final alerts       = pigs.getAlerts();

    return RefreshIndicator(
      color: AppColors.primary, onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary cards
          Row(children: [
            Expanded(child: _MiniCard('Total Records', '${health.length}', AppColors.primary, Icons.medical_services_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MiniCard('Active Alerts', '${alerts.length}', AppColors.danger, Icons.warning_rounded)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MiniCard('Vaccinations', '$vaccinations', AppColors.blue, Icons.vaccines_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MiniCard('Treatments', '$treatments', AppColors.warning, Icons.healing_rounded)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MiniCard('Dewormings', '$dewormings', AppColors.success, Icons.pest_control_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _MiniCard('Checkups', '$checkups', AppColors.primary, Icons.health_and_safety_rounded)),
          ]),
          const SizedBox(height: 16),

          // Active alerts — sick or quarantine pigs
          if (alerts.isNotEmpty) ...[
            _SectionHeader('⚠️ Active Alerts (${alerts.length})'),
            ...alerts.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
              child: Row(children: [
                Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_rounded, size: 20, color: AppColors.danger)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger, fontFamily: 'Poppins')),
                  Text('${p.tagId} · ${p.status.label}', style: const TextStyle(fontSize: 11, color: AppColors.danger, fontFamily: 'Poppins')),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: p.status.bgColor, borderRadius: BorderRadius.circular(10)), child: Text(p.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.status.color, fontFamily: 'Poppins'))),
              ]),
            )),
            const SizedBox(height: 16),
          ],

          // Health by type pie chart
          if (byType.isNotEmpty) ...[
            _SectionHeader('Records by Type'),
            _PieSection(byType),
            const SizedBox(height: 16),
          ],

          // Records by status
          if (byStatus.isNotEmpty) ...[
            _SectionHeader('Records by Status'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
              child: Column(children: byStatus.entries.map((e) => _CategoryRow(label: e.key[0].toUpperCase() + e.key.substring(1), amount: '${e.value} record${e.value != 1 ? "s" : ""}', pct: health.isEmpty ? 0 : e.value / health.length)).toList()),
            ),
            const SizedBox(height: 16),
          ],

          // Recent health records
          _SectionHeader('Recent Health Records'),
          health.isEmpty
              ? Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.health_and_safety_rounded, size: 48, color: AppColors.gray200), const SizedBox(height: 12),
              const Text('No health records yet', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              GestureDetector(onTap: onRefresh, child: const Text('Tap to refresh', style: TextStyle(fontSize: 12, color: AppColors.primary, fontFamily: 'Poppins', fontWeight: FontWeight.w600))),
            ]),
          )
              : Column(children: health.take(15).map((h) {
            Color typeColor, typeBg;
            IconData typeIcon;
            switch (h.type) {
              case 'Vaccination': typeColor = AppColors.blue; typeBg = AppColors.blueBg; typeIcon = Icons.vaccines_rounded; break;
              case 'Treatment':   typeColor = AppColors.danger; typeBg = AppColors.dangerBg; typeIcon = Icons.medical_services_rounded; break;
              case 'Deworming':   typeColor = AppColors.warning; typeBg = AppColors.warningBg; typeIcon = Icons.pest_control_rounded; break;
              case 'Breeding':    typeColor = const Color(0xFFEC4899); typeBg = const Color(0xFFFCE7F3); typeIcon = Icons.favorite_rounded; break;
              case 'Farrowing':   typeColor = const Color(0xFFEC4899); typeBg = const Color(0xFFFCE7F3); typeIcon = Icons.child_care_rounded; break;
              default:            typeColor = AppColors.success; typeBg = AppColors.successBg; typeIcon = Icons.health_and_safety_rounded;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(11)), child: Icon(typeIcon, size: 20, color: typeColor)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(20)), child: Text(h.type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: typeColor, fontFamily: 'Poppins'))),
                    const SizedBox(width: 6),
                    Text(h.pigName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins')),
                  ]),
                  const SizedBox(height: 2),
                  Text(h.condition, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                  if (h.treatment != null) Text('Tx: ${h.treatment}', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${h.date.day}/${h.date.month}/${h.date.year}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: h.status == 'recovered' ? AppColors.successBg : h.status == 'critical' ? AppColors.dangerBg : AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                    child: Text(h.status[0].toUpperCase() + h.status.substring(1), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: h.status == 'recovered' ? AppColors.success : h.status == 'critical' ? AppColors.danger : AppColors.warning)),
                  ),
                ]),
              ]),
            );
          }).toList()),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String title, value; final Color color; final IconData icon;
  const _MiniCard(this.title, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color, fontFamily: 'Poppins')),
      Text(title, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
    ]),
  );
}

Widget _SectionHeader(String title) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
);

class _CategoryRow extends StatelessWidget {
  final String label, amount; final double pct;
  const _CategoryRow({required this.label, required this.amount, required this.pct});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins'))),
        Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gray600, fontFamily: 'Poppins')),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), backgroundColor: AppColors.gray100, valueColor: const AlwaysStoppedAnimation(AppColors.primary), minHeight: 6)),
    ]),
  );
}

class _PieSection extends StatelessWidget {
  final Map<String, int> data;
  const _PieSection(this.data);
  static const _colors = [AppColors.primary, AppColors.success, AppColors.warning, AppColors.blue, AppColors.danger, Color(0xFFEC4899), Color(0xFF7C3AED)];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold(0, (s, e) => s + e.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
      child: Row(children: [
        SizedBox(width: 120, height: 120, child: PieChart(PieChartData(
          sections: List.generate(entries.length, (i) => PieChartSectionData(value: entries[i].value.toDouble(), color: _colors[i % _colors.length], radius: 42, showTitle: false)),
          sectionsSpace: 2, centerSpaceRadius: 26,
        ))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: List.generate(entries.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text('${entries[i].key}', style: const TextStyle(fontSize: 12, fontFamily: 'Poppins', color: AppColors.dark))),
            Text('${entries[i].value} (${total > 0 ? (entries[i].value / total * 100).toStringAsFixed(0) : 0}%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray600, fontFamily: 'Poppins')),
          ]),
        )))),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color; final String label;
  const _LegendDot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins')),
  ]);
}

Widget _InfoRow2(IconData icon, Color color, String label, String value) => Row(children: [
  Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
  const SizedBox(width: 10),
  Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins')),
  Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis)),
]);