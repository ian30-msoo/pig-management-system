// lib/screens/feeding/feeding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/pig_model.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/common/widgets.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  List<FeedRecord> _records = [];
  bool             _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final provider = context.read<PigProvider>();
    final pigs     = provider.activePigs;

    final results = await Future.wait(
      pigs.map((p) => provider.getPigFeeding(p.id)),
    );

    final all = results.expand((list) => list).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (mounted) setState(() { _records = all; _loading = false; });
  }

  double get _todayKg {
    final now = DateTime.now();
    return _records
        .where((r) =>
    r.date.day == now.day &&
        r.date.month == now.month &&
        r.date.year == now.year)
        .fold(0, (s, r) => s + r.quantityKg);
  }

  double get _monthKg {
    final now = DateTime.now();
    return _records
        .where((r) => r.date.month == now.month && r.date.year == now.year)
        .fold(0, (s, r) => s + r.quantityKg);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PigProvider>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20, right: 20, bottom: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.primary, // ← was green gradient
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chevron_left_rounded, size: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Feeding Records',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                  if (!_loading)
                    Text('${_records.length} record${_records.length != 1 ? "s" : ""}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Poppins')),
                ]),
              ),
              GestureDetector(
                onTap: _loadAll,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final pigs = context.read<PigProvider>().activePigs;
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _AddFeedingSheet(
                      pigs: pigs.map((p) => {'id': p.id, 'name': p.name}).toList(),
                      onSaved: _loadAll,
                    ),
                  );
                },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                ),
              ),
            ]),

            if (!_loading && _records.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Today', style: TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Poppins')),
                      Text('${_todayKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                      const Text('fed today', style: TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'Poppins')),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('This Month', style: TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Poppins')),
                      Text('${_monthKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                      const Text('total feed', style: TextStyle(fontSize: 10, color: Colors.white60, fontFamily: 'Poppins')),
                    ]),
                  ),
                ),
              ]),
            ],
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: AppColors.primary), // ← was AppColors.success
                SizedBox(height: 14),
                Text('Loading feeding records...', style: TextStyle(color: AppColors.gray400, fontFamily: 'Poppins', fontSize: 13)),
              ]))
              : _records.isEmpty
              ? _EmptyFeeding(
            onAdd: () async {
              final pigs = context.read<PigProvider>().activePigs;
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AddFeedingSheet(
                  pigs: pigs.map((p) => {'id': p.id, 'name': p.name}).toList(),
                  onSaved: _loadAll,
                ),
              );
            },
          )
              : RefreshIndicator(
            onRefresh: _loadAll,
            color: AppColors.primary, // ← was AppColors.success
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              itemCount: _records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final f = _records[i];
                return _FeedCard(
                  record: f,
                  onDelete: () async {
                    final ok = await context.read<PigProvider>().deleteFeedRecord(f.pigId, f.id);
                    if (ok) _loadAll();
                  },
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final FeedRecord   record;
  final VoidCallback onDelete;
  const _FeedCard({required this.record, required this.onDelete});

  Color _feedColor(String t) {
    switch (t.toLowerCase()) {
      case 'starter':       return const Color(0xFF7C3AED);
      case 'grower':        return const Color(0xFF10B981);
      case 'finisher':      return const Color(0xFFE8253F);
      case 'sow & weaner':  return const Color(0xFF0EA5E9);
      default:              return const Color(0xFF6366F1);
    }
  }

  Color _feedBg(String t) {
    switch (t.toLowerCase()) {
      case 'starter':       return const Color(0xFFEDE9FE);
      case 'grower':        return const Color(0xFFD1FAE5);
      case 'finisher':      return const Color(0xFFFEE2E2);
      case 'sow & weaner':  return const Color(0xFFE0F2FE);
      default:              return const Color(0xFFE0E7FF);
    }
  }

  IconData _feedIcon(String t) {
    switch (t.toLowerCase()) {
      case 'starter':       return Icons.baby_changing_station_rounded;
      case 'grower':        return Icons.eco_rounded;
      case 'finisher':      return Icons.fitness_center_rounded;
      case 'sow & weaner':  return Icons.water_rounded;
      default:              return Icons.set_meal_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f     = record;
    final color = _feedColor(f.feedType);
    final bg    = _feedBg(f.feedType);
    final icon  = _feedIcon(f.feedType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(f.pigName ?? f.pigId,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), fontFamily: 'Poppins')),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(maxWidth: 110),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(f.feedType,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.monitor_weight_rounded, size: 11, color: color),
                    const SizedBox(width: 3),
                    Text('${f.quantityKg.toStringAsFixed(1)} kg',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, fontFamily: 'Poppins')),
                  ]),
                ),
                if (f.brand != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(f.brand!, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'Poppins')),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text('${_weekday(f.date.weekday)}, ${f.date.day}/${f.date.month}/${f.date.year}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontFamily: 'Poppins')),
              if (f.notes != null) ...[
                const SizedBox(height: 2),
                Text(f.notes!, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontFamily: 'Poppins', fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF9CA3AF)),
            ),
          ),
        ]),
      ),
    );
  }

  String _weekday(int w) {
    const d = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return d[(w - 1).clamp(0, 6)];
  }
}

class _EmptyFeeding extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyFeeding({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: AppColors.primaryBg, // ← was AppColors.successBg
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
            child: Icon(Icons.eco_rounded, size: 44, color: AppColors.primary)), // ← was AppColors.success
      ),
      const SizedBox(height: 18),
      const Text('No Feeding Records',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
      const SizedBox(height: 6),
      const Text('Start tracking your pig feeding schedule',
          style: TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins')),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
              color: AppColors.primary, // ← was AppColors.success
              borderRadius: BorderRadius.circular(14)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Record Feeding',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
          ]),
        ),
      ),
    ]),
  );
}

class _AddFeedingSheet extends StatefulWidget {
  final List<Map<String, String>> pigs;
  final VoidCallback onSaved;
  const _AddFeedingSheet({required this.pigs, required this.onSaved});

  @override
  State<_AddFeedingSheet> createState() => _AddFeedingSheetState();
}

class _AddFeedingSheetState extends State<_AddFeedingSheet> {
  final _form  = GlobalKey<FormState>();
  final _qty   = TextEditingController();
  final _brand = TextEditingController();
  final _notes = TextEditingController();

  String? _pigId;
  String? _pigName;
  String  _feedType = AppConstants.feedTypes.first;
  bool    _loading  = false;

  @override
  void dispose() {
    _qty.dispose();
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: const BoxDecoration(
            color: AppColors.primary, // ← was green gradient
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Row(children: [
            const Text('Record Feeding',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
            const Spacer(),
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(children: [
                AppCard(
                  child: Column(children: [
                    _FormLabel('Select Pig'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _pigId,
                      hint: const Text('Choose pig...', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.savings_rounded, size: 18, color: AppColors.gray400)),
                      items: widget.pigs.map((p) => DropdownMenuItem(
                        value: p['id'],
                        child: Text(p['name']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                      )).toList(),
                      validator: (v) => v == null ? 'Please select a pig' : null,
                      onChanged: (v) => setState(() {
                        _pigId   = v;
                        _pigName = widget.pigs.firstWhere((p) => p['id'] == v)['name'];
                      }),
                    ),
                    const SizedBox(height: 16),

                    _FormLabel('Feed Type'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _feedType,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.eco_rounded, size: 18, color: AppColors.gray400)),
                      items: AppConstants.feedTypes.map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                      )).toList(),
                      onChanged: (v) => setState(() => _feedType = v!),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Quantity (kg) *',
                      hint: 'e.g. 2.5',
                      controller: _qty,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.monitor_weight_rounded, size: 18, color: AppColors.gray400),
                      validator: (v) => AppValidators.positiveNumber(v, 'Quantity'),
                    ),
                    AppTextField(
                      label: 'Brand (optional)',
                      hint: 'e.g. Unga Feeds, Pembe',
                      controller: _brand,
                      prefixIcon: const Icon(Icons.label_rounded, size: 18, color: AppColors.gray400),
                    ),
                    AppTextField(
                      label: 'Notes (optional)',
                      hint: 'Any observations...',
                      controller: _notes,
                      maxLines: 2,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Feeding Record',
                  icon: Icons.check_rounded,
                  loading: _loading,
                  color: AppColors.primary, // ← was AppColors.success
                  onPressed: _save,
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_pigId == null) return;
    setState(() => _loading = true);

    final now    = DateTime.now();
    final record = FeedRecord(
      id:         '',
      pigId:      _pigId!,
      pigName:    _pigName,
      feedType:   _feedType,
      quantityKg: double.tryParse(_qty.text.trim()) ?? 0,
      brand:      _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      notes:      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      date:       now,
      createdAt:  now,
    );

    await context.read<PigProvider>().addFeedRecord(_pigId!, record);
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
    }
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'Poppins')),
  );
}