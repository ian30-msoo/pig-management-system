// lib/screens/breeding/breeding_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/pig_model.dart';

class BreedingScreen extends StatefulWidget {
  const BreedingScreen({super.key});
  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int _ageMonths(PigModel p) =>
      (DateTime.now().difference(p.birthDate).inDays / 30).floor();

  bool _isSow(PigModel p) {
    final stage = p.stage.toLowerCase();
    return p.gender == PigGender.female &&
        (stage == 'sow' || stage == 'gilt' || stage == 'grower' ||
            stage == 'finisher' || _ageMonths(p) >= 5);
  }

  bool _isBoar(PigModel p) {
    final stage = p.stage.toLowerCase();
    return p.gender == PigGender.male &&
        (stage == 'boar' || stage == 'grower' || stage == 'finisher' ||
            _ageMonths(p) >= 5);
  }

  bool _isGilt(PigModel p) {
    final stage = p.stage.toLowerCase();
    return p.gender == PigGender.female &&
        (stage == 'gilt' ||
            (stage != 'sow' && _ageMonths(p) >= 4 && _ageMonths(p) < 10));
  }

  @override
  Widget build(BuildContext context) {
    final pigs = context.watch<PigProvider>();

    // ✅ Show ALL active females and males — no strict age gate
    final females     = pigs.activePigs.where((p) => p.gender == PigGender.female).toList();
    final males       = pigs.activePigs.where((p) => p.gender == PigGender.male).toList();
    final allBreeding = [...females, ...males];
    final sows        = females.where(_isSow).toList();
    final gilts       = females.where(_isGilt).toList();

    final List<PigModel> filtered;
    switch (_filter) {
      case 'Sows':   filtered = females; break;
      case 'Boars':  filtered = males;   break;
      case 'Gilts':  filtered = gilts;   break;
      default:       filtered = allBreeding; break;
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20, right: 20, bottom: 0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              const Expanded(
                child: Text('Breeding & Reproduction',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Colors.white, fontFamily: 'Poppins')),
              ),
              GestureDetector(
                onTap: () => _showGuide(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.info_outline_rounded,
                      size: 22, color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              _BreedingStat('Females', '${females.length}',
                  Icons.female_rounded, const Color(0xFFEC4899)),
              const SizedBox(width: 8),
              _BreedingStat('Males', '${males.length}',
                  Icons.male_rounded, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _BreedingStat('Sows', '${sows.length}',
                  Icons.favorite_rounded, const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _BreedingStat('Total', '${allBreeding.length}',
                  Icons.pets_rounded, Colors.white),
            ]),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Sows', 'Boars', 'Gilts']
                    .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 14),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                          color: _filter == f
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(f,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _filter == f
                                  ? AppColors.primary
                                  : Colors.white,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyBreeding(
            filter: _filter,
            totalPigs: pigs.activePigs.length,
            onAdd: () => _showGuide(context),
          )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _BreedingCard(
              pig: filtered[i],
              ageMonths: _ageMonths(filtered[i]),
              allMales: males,
              onRecordMating: () =>
                  _showRecordMatingDialog(context, filtered[i], males),
              onRecordFarrowing: () =>
                  _showRecordFarrowingDialog(context, filtered[i]),
              onViewHistory: () =>
                  _showBreedingHistory(context, filtered[i]),
            ),
          ),
        ),
      ]),
    );
  }

  void _showGuide(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Breeding Guide',
              style: TextStyle(fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Ideal Breeding Ages:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.gray600, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              ...[
                'Gilts: first mating at 7–9 months, >80 kg',
                'Sows: re-mate 5–7 days after weaning',
                'Boars: ready at 8+ months, >100 kg',
                'Gestation: ~115 days (3m 3w 3d)',
                'Optimal mating: 12–24 hrs after heat',
              ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tip,
                            style: const TextStyle(fontSize: 12,
                                color: AppColors.dark, fontFamily: 'Poppins'))),
                      ]))),
            ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It',
                style: TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          )
        ],
      ),
    );
  }

  void _showRecordMatingDialog(BuildContext ctx, PigModel pig, List<PigModel> males) {
    final partnerCtrl = TextEditingController();
    DateTime matingDate = DateTime.now();
    bool saving = false;

    showDialog(
      context: ctx,
      builder: (dctx) => StatefulBuilder(builder: (dctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            pig.gender == PigGender.female
                ? 'Record Mating — ${pig.name}'
                : 'Record Mating — ${pig.name} (Boar)',
            style: const TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w700, fontSize: 15)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Mating Date',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.gray600, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx,
                  initialDate: matingDate,
                  firstDate: DateTime(2024), lastDate: DateTime.now());
              if (d != null) setS(() => matingDate = d);
            },
            child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray200)),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('${matingDate.day}/${matingDate.month}/${matingDate.year}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  const Spacer(),
                  const Text('Change',
                      style: TextStyle(fontSize: 11, color: AppColors.primary,
                          fontFamily: 'Poppins')),
                ])),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: partnerCtrl,
              decoration: InputDecoration(
                labelText: pig.gender == PigGender.female
                    ? 'Boar Name/Tag' : 'Sow Name/Tag',
                hintText: males.isNotEmpty
                    ? males.first.name : 'e.g. Bwana (P002)',
                filled: true, fillColor: AppColors.offWhite,
                prefixIcon: Icon(
                    pig.gender == PigGender.female
                        ? Icons.male_rounded : Icons.female_rounded,
                    size: 18, color: AppColors.blue),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.gray200)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
          if (pig.gender == PigGender.female) ...[
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.child_care_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                      'Expected farrowing: ${_farrowingDate(matingDate)}',
                      style: const TextStyle(fontSize: 11,
                          color: AppColors.primary, fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600))),
                ])),
          ],
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.gray600, fontFamily: 'Poppins'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: saving ? null : () async {
              setS(() => saving = true);
              final partner = partnerCtrl.text.trim().isEmpty
                  ? (males.isNotEmpty ? '${males.first.name} (${males.first.tagId})' : 'Unknown')
                  : partnerCtrl.text.trim();
              final record = HealthRecord(
                id: '', pigId: pig.id, pigName: pig.name,
                type: 'Breeding',
                condition: pig.gender == PigGender.female
                    ? 'Mated with $partner'
                    : 'Used as sire with $partner',
                notes: pig.gender == PigGender.female
                    ? 'Expected farrowing: ${_farrowingDate(matingDate)}'
                    : null,
                date: matingDate, createdAt: DateTime.now(),
              );
              await context.read<PigProvider>().addHealthRecord(pig.id, record);
              if (dctx.mounted) Navigator.pop(dctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Mating recorded for ${pig.name}',
                        style: const TextStyle(fontFamily: 'Poppins')),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating));
              }
            },
            child: saving
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Record Mating',
                style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      )),
    );
  }

  void _showRecordFarrowingDialog(BuildContext ctx, PigModel sow) {
    if (sow.gender != PigGender.female) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Farrowing is only for female pigs',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating));
      return;
    }
    final litterCtrl = TextEditingController();
    final aliveCtrl  = TextEditingController();
    final notesCtrl  = TextEditingController();
    DateTime farrowDate = DateTime.now();
    bool saving = false;

    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Record Farrowing — ${sow.name}',
          style: const TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.w700, fontSize: 15)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(context: ctx,
                initialDate: farrowDate,
                firstDate: DateTime(2024), lastDate: DateTime.now());
            if (d != null) setS(() => farrowDate = d);
          },
          child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray200)),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Farrowing: ${farrowDate.day}/${farrowDate.month}/${farrowDate.year}',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                const Spacer(),
                const Text('Change',
                    style: TextStyle(fontSize: 11, color: AppColors.primary,
                        fontFamily: 'Poppins')),
              ])),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: litterCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Litter',
                  hintText: '10', filled: true, fillColor: AppColors.offWhite,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: aliveCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Born Alive',
                  hintText: '9', filled: true, fillColor: AppColors.offWhite,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
        ]),
        const SizedBox(height: 12),
        TextField(controller: notesCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)',
                hintText: 'Birth weights, complications...',
                filled: true, fillColor: AppColors.offWhite,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.gray600, fontFamily: 'Poppins'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: saving ? null : () async {
            setS(() => saving = true);
            final litter = litterCtrl.text.trim();
            final alive  = aliveCtrl.text.trim();
            final record = HealthRecord(
              id: '', pigId: sow.id, pigName: sow.name,
              type: 'Farrowing',
              condition: 'Farrowed — $alive/${litter.isEmpty ? "?" : litter} piglets born alive',
              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              status: 'recovered',
              date: farrowDate, createdAt: DateTime.now(),
            );
            await context.read<PigProvider>().addHealthRecord(sow.id, record);
            if (dctx.mounted) Navigator.pop(dctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Farrowing recorded for ${sow.name}!',
                      style: const TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: const Color(0xFFEC4899),
                  behavior: SnackBarBehavior.floating));
            }
          },
          child: saving
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Record Farrowing',
              style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ],
    )));
  }

  void _showBreedingHistory(BuildContext ctx, PigModel pig) async {
    final records = await ctx.read<PigProvider>().getPigHealth(pig.id);
    final breedingRecs = records.where((r) =>
    r.type == 'Breeding' || r.type == 'Farrowing').toList();
    if (!ctx.mounted) return;
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: const BoxDecoration(color: AppColors.offWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(children: [
              const Icon(Icons.history_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Breeding History — ${pig.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Poppins'))),
              GestureDetector(onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded, color: Colors.white)),
            ]),
          ),
          Expanded(child: breedingRecs.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.gray200),
            SizedBox(height: 12),
            Text('No breeding records yet', style: TextStyle(fontSize: 14,
                color: AppColors.gray400, fontFamily: 'Poppins')),
            SizedBox(height: 4),
            Text('Tap "Record Mating" on the card', style: TextStyle(fontSize: 12,
                color: AppColors.gray400, fontFamily: 'Poppins')),
          ]))
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: breedingRecs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = breedingRecs[i];
              final isF = r.type == 'Farrowing';
              return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: isF ? const Color(0xFFEC4899).withValues(alpha: 0.1) : AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(isF ? Icons.child_care_rounded : Icons.favorite_rounded,
                            size: 20, color: isF ? const Color(0xFFEC4899) : AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                                color: isF ? const Color(0xFFEC4899).withValues(alpha: 0.1) : AppColors.primaryBg,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(r.type, style: TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isF ? const Color(0xFFEC4899) : AppColors.primary,
                                fontFamily: 'Poppins'))),
                        const Spacer(),
                        Text('${r.date.day}/${r.date.month}/${r.date.year}',
                            style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                      ]),
                      const SizedBox(height: 4),
                      Text(r.condition, style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                      if (r.notes != null) Text(r.notes!, style: const TextStyle(fontSize: 11,
                          color: AppColors.gray600, fontFamily: 'Poppins')),
                    ])),
                  ]));
            },
          )),
        ]),
      ),
    );
  }

  String _farrowingDate(DateTime d) {
    final f = d.add(const Duration(days: 115));
    return '${f.day}/${f.month}/${f.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BREEDING CARD — with maturity progress bar
// ─────────────────────────────────────────────────────────────────────────────

class _BreedingCard extends StatefulWidget {
  final PigModel     pig;
  final int          ageMonths;
  final List<PigModel> allMales;
  final VoidCallback onRecordMating;
  final VoidCallback onRecordFarrowing;
  final VoidCallback onViewHistory;

  const _BreedingCard({
    required this.pig,
    required this.ageMonths,
    required this.allMales,
    required this.onRecordMating,
    required this.onRecordFarrowing,
    required this.onViewHistory,
  });
  @override
  State<_BreedingCard> createState() => _BreedingCardState();
}

class _BreedingCardState extends State<_BreedingCard> {
  List<HealthRecord> _records = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await context.read<PigProvider>().getPigHealth(widget.pig.id);
    if (mounted) setState(() => _records =
        all.where((r) => r.type == 'Breeding' || r.type == 'Farrowing').toList());
  }

  bool get _isMature {
    final isFem = widget.pig.gender == PigGender.female;
    return widget.ageMonths >= (isFem ? 7 : 8);
  }

  String get _maturityLabel {
    final isFem = widget.pig.gender == PigGender.female;
    if (_isMature) return isFem ? '✓ Ready to breed' : '✓ Ready to sire';
    final needed = (isFem ? 7 : 8) - widget.ageMonths;
    return '~$needed month${needed != 1 ? "s" : ""} to maturity';
  }

  Color get _mc => _isMature ? AppColors.success : AppColors.warning;

  double get _progress {
    final target = (widget.pig.gender == PigGender.female ? 7.0 : 8.0);
    return (widget.ageMonths / target).clamp(0.0, 1.0);
  }

  String _farrowingDate(DateTime d) {
    final f = d.add(const Duration(days: 115));
    return '${f.day}/${f.month}/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pig      = widget.pig;
    final isFemale = pig.gender == PigGender.female;
    final color    = isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
    final icon     = isFemale ? Icons.female_rounded : Icons.male_rounded;

    final lastMating  = _records.where((r) => r.type == 'Breeding').isNotEmpty
        ? _records.where((r) => r.type == 'Breeding').first : null;
    final litterCount = _records.where((r) => r.type == 'Farrowing').length;

    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              // Avatar — shows pig photo if available
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: pig.imageUrl != null && pig.imageUrl!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(pig.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: color, size: 28)),
                )
                    : Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(pig.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.dark, fontFamily: 'Poppins'))),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(pig.stage, style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins'))),
                ]),
                Text('${pig.tagId} · ${pig.breed}',
                    style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
                Text('${widget.ageMonths} months · ${pig.weight.toStringAsFixed(0)} kg',
                    style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins')),
              ])),
            ]),
            const SizedBox(height: 12),

            // ── Maturity progress bar ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _mc.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _mc.withValues(alpha: 0.3))),
              child: Column(children: [
                Row(children: [
                  Icon(_isMature ? Icons.check_circle_rounded : Icons.access_time_rounded,
                      size: 14, color: _mc),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_maturityLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: _mc, fontFamily: 'Poppins'))),
                  Text('${widget.ageMonths}m / ${isFemale ? 7 : 8}m',
                      style: TextStyle(fontSize: 11, color: _mc, fontFamily: 'Poppins')),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress, minHeight: 6,
                    backgroundColor: _mc.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(_mc),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Key info ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.offWhite, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                if (isFemale) ...[
                  _InfoRow(Icons.favorite_rounded, 'Last Mating',
                      lastMating != null
                          ? '${lastMating.date.day}/${lastMating.date.month}/${lastMating.date.year}'
                          : 'Not recorded'),
                  if (lastMating != null)
                    _InfoRow(Icons.child_care_rounded, 'Expected Farrowing',
                        _farrowingDate(lastMating.date)),
                  _InfoRow(Icons.list_alt_rounded, 'Litters Recorded',
                      '$litterCount farrowing${litterCount != 1 ? "s" : ""}'),
                ] else ...[
                  _InfoRow(Icons.male_rounded, 'Role', 'Breeding Boar / Sire'),
                  _InfoRow(Icons.list_alt_rounded, 'Matings Recorded',
                      '${_records.where((r) => r.type == "Breeding").length}'),
                  _InfoRow(Icons.calendar_month_rounded, 'Last Active',
                      _records.isNotEmpty
                          ? '${_records.first.date.day}/${_records.first.date.month}/${_records.first.date.year}'
                          : 'Not recorded'),
                ],
              ]),
            ),
          ]),
        ),

        // ── Action row ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(children: [
            Expanded(child: _ActionBtn('Record Mating', Icons.favorite_rounded,
                AppColors.primary, widget.onRecordMating)),
            if (isFemale) ...[
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn('Log Farrowing', Icons.child_care_rounded,
                  const Color(0xFFEC4899), widget.onRecordFarrowing)),
            ],
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onViewHistory,
              child: Container(width: 40, height: 36,
                  decoration: BoxDecoration(color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gray200)),
                  child: const Icon(Icons.history_rounded, size: 18, color: AppColors.gray400)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

Widget _InfoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.gray400),
      const SizedBox(width: 8),
      Text('$label:', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins')),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
          color: AppColors.dark, fontFamily: 'Poppins')),
    ]));

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: color), const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: color, fontFamily: 'Poppins')),
          ])));
}

class _BreedingStat extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _BreedingStat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Icon(icon, color: color == Colors.white ? Colors.white : color, size: 18),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800,
                color: Colors.white, fontSize: 16, fontFamily: 'Poppins')),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70,
                fontFamily: 'Poppins')),
          ])));
}

class _EmptyBreeding extends StatelessWidget {
  final String filter; final int totalPigs; final VoidCallback onAdd;
  const _EmptyBreeding({required this.filter, required this.totalPigs, required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.favorite_rounded, size: 40, color: AppColors.primary)),
        const SizedBox(height: 16),
        Text(totalPigs == 0 ? 'No Pigs Added Yet'
            : filter == 'All' ? 'No Female or Male Pigs' : 'No $filter Found',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                color: AppColors.dark, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        Text(totalPigs == 0
            ? 'Add pigs in "My Pigs" first, then return here to manage breeding.'
            : 'Go to My Pigs → Add Pig and set the gender to Male or Female.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.gray400,
                fontFamily: 'Poppins', height: 1.5)),
        const SizedBox(height: 6),
        const Text('Any active male or female pig will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.primary,
                fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}