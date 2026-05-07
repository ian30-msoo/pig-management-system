// lib/screens/vet/vet_cases_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/common/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VET CASE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class VetCase {
  final String   id, vetId, vetName, farmerName, farmerPhone;
  final String   pigName, pigTagId, condition, treatment;
  final String?  medication, notes;
  final String   status; // 'open' | 'follow_up' | 'resolved'
  final DateTime? followUpDate;
  final DateTime  createdAt;

  VetCase({
    required this.id, required this.vetId, required this.vetName,
    required this.farmerName, required this.farmerPhone,
    required this.pigName, required this.pigTagId,
    required this.condition, required this.treatment,
    this.medication, this.notes, required this.status,
    this.followUpDate, required this.createdAt,
  });

  factory VetCase.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VetCase(
      id:          doc.id,
      vetId:       d['vetId']       ?? '',
      vetName:     d['vetName']     ?? '',
      farmerName:  d['farmerName']  ?? '',
      farmerPhone: d['farmerPhone'] ?? '',
      pigName:     d['pigName']     ?? '',
      pigTagId:    d['pigTagId']    ?? '',
      condition:   d['condition']   ?? '',
      treatment:   d['treatment']   ?? '',
      medication:  d['medication'],
      notes:       d['notes'],
      status:      d['status']      ?? 'open',
      followUpDate: (d['followUpDate'] as Timestamp?)?.toDate(),
      createdAt:   (d['createdAt']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'vetId': vetId, 'vetName': vetName,
    'farmerName': farmerName, 'farmerPhone': farmerPhone,
    'pigName': pigName, 'pigTagId': pigTagId,
    'condition': condition, 'treatment': treatment,
    'medication': medication, 'notes': notes, 'status': status,
    'followUpDate': followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  VET CASES SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class VetCasesScreen extends StatefulWidget {
  const VetCasesScreen({super.key});
  @override
  State<VetCasesScreen> createState() => _VetCasesScreenState();
}

class _VetCasesScreenState extends State<VetCasesScreen> {
  final _db    = FirebaseFirestore.instance;
  String _filter = 'All';

  Stream<List<VetCase>> _stream(String vetId) =>
      _db.collection('vet_cases')
          .where('vetId', isEqualTo: vetId)
          .snapshots()
          .map((s) {
        final list = s.docs.map(VetCase.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
  List<VetCase> _apply(List<VetCase> all) {
    switch (_filter) {
      case 'Open':      return all.where((c) => c.status == 'open').toList();
      case 'Follow-up': return all.where((c) => c.status == 'follow_up').toList();
      case 'Resolved':  return all.where((c) => c.status == 'resolved').toList();
      default:          return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final uid  = auth.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [

        // ── Header — NO back button (tab page) ──────────────────────────
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 20, right: 20, bottom: 0,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('My Cases', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                Text('Veterinary case records', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Poppins')),
              ])),
              GestureDetector(
                onTap: () => _openAddSheet(context, uid, auth.user?.fullName ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('New Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Poppins')),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Open', 'Follow-up', 'Resolved'].map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 14),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: _filter == f ? Colors.white : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _filter == f ? AppColors.primary : Colors.white, fontFamily: 'Poppins')),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ]),
        ),

        // ── Content ─────────────────────────────────────────────────────
        Expanded(
          child: uid.isEmpty
              ? const Center(child: Text('Not signed in', style: TextStyle(fontFamily: 'Poppins', color: AppColors.gray400)))
              : StreamBuilder<List<VetCase>>(
            stream: _stream(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snap.hasError) {
                return Center(child: Text('Error loading cases', style: const TextStyle(fontFamily: 'Poppins', color: AppColors.danger)));
              }

              final all      = snap.data ?? [];
              final filtered = _apply(all);
              final open     = all.where((c) => c.status == 'open').length;
              final followUp = all.where((c) => c.status == 'follow_up').length;
              final resolved = all.where((c) => c.status == 'resolved').length;

              return Column(children: [
                // Summary bar
                if (all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                      child: Row(children: [
                        _SumBadge('$open', 'Open', AppColors.danger),
                        const SizedBox(width: 8),
                        _SumBadge('$followUp', 'Follow-up', AppColors.warning),
                        const SizedBox(width: 8),
                        _SumBadge('$resolved', 'Resolved', AppColors.success),
                      ]),
                    ),
                  ),

                Expanded(
                  child: filtered.isEmpty
                      ? _Empty(filter: _filter, onAdd: () => _openAddSheet(context, uid, auth.user?.fullName ?? ''))
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CaseCard(
                      vetCase: filtered[i],
                      onDelete: () => _delete(context, filtered[i].id),
                      onUpdateStatus: (s) => _updateStatus(filtered[i].id, s),
                    ),
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  void _openAddSheet(BuildContext ctx, String vetId, String vetName) =>
      showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => _AddCaseSheet(vetId: vetId, vetName: vetName));

  Future<void> _delete(BuildContext ctx, String id) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Case?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      content: const Text('This will permanently delete the case record.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.gray600)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok == true) _db.collection('vet_cases').doc(id).delete();
  }

  Future<void> _updateStatus(String id, String status) =>
      _db.collection('vet_cases').doc(id).update({'status': status});
}

// ─────────────────────────────────────────────────────────────────────────────
//  CASE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CaseCard extends StatelessWidget {
  final VetCase vetCase;
  final VoidCallback onDelete;
  final void Function(String) onUpdateStatus;
  const _CaseCard({required this.vetCase, required this.onDelete, required this.onUpdateStatus});

  Color  _sc(String s) { switch (s) { case 'resolved': return AppColors.success; case 'follow_up': return AppColors.warning; default: return AppColors.danger; } }
  Color  _sb(String s) { switch (s) { case 'resolved': return AppColors.successBg; case 'follow_up': return AppColors.warningBg; default: return AppColors.dangerBg; } }
  String _sl(String s) { switch (s) { case 'resolved': return 'Resolved'; case 'follow_up': return 'Follow-up'; default: return 'Open'; } }

  @override
  Widget build(BuildContext context) {
    final c = vetCase;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.medical_services_rounded, size: 22, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.condition, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _sb(c.status), borderRadius: BorderRadius.circular(20)), child: Text(_sl(c.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _sc(c.status), fontFamily: 'Poppins'))),
            ]),
            const SizedBox(height: 3),
            Row(children: [const Icon(Icons.person_rounded, size: 12, color: AppColors.gray400), const SizedBox(width: 4), Expanded(child: Text('${c.farmerName} · ${c.farmerPhone}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')))]),
            const SizedBox(height: 2),
            Row(children: [const Icon(Icons.pets_rounded, size: 12, color: AppColors.primary), const SizedBox(width: 4), Text('${c.pigName} (${c.pigTagId})', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins'))]),
            const SizedBox(height: 5),
            if (c.treatment.isNotEmpty) Text('Tx: ${c.treatment}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins')),
            if (c.medication != null) Text('💊 ${c.medication}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins')),
            if (c.followUpDate != null) Row(children: [const Icon(Icons.event_rounded, size: 12, color: AppColors.warning), const SizedBox(width: 4), Text('Follow-up: ${c.followUpDate!.day}/${c.followUpDate!.month}/${c.followUpDate!.year}', style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600, fontFamily: 'Poppins'))]),
          ])),
          GestureDetector(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.gray400))),
        ])),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18))),
          child: Row(children: [
            Text('${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
            const Spacer(),
            if (c.status != 'resolved') ...[
              if (c.status == 'open') _Chip('Follow-up', AppColors.warning, () => onUpdateStatus('follow_up')),
              const SizedBox(width: 6),
              _Chip('Resolve', AppColors.success, () => onUpdateStatus('resolved')),
            ] else
              const Row(children: [Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success), SizedBox(width: 4), Text('Resolved', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600, fontFamily: 'Poppins'))]),
          ]),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _Chip(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.4))),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'Poppins')),
  ));
}

class _SumBadge extends StatelessWidget {
  final String count, label; final Color color;
  const _SumBadge(this.count, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'Poppins')),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
    ]),
  ));
}

class _Empty extends StatelessWidget {
  final String filter; final VoidCallback onAdd;
  const _Empty({required this.filter, required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 90, height: 90, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(28)), child: const Center(child: Icon(Icons.medical_services_rounded, size: 44, color: AppColors.primary))),
    const SizedBox(height: 18),
    Text(filter == 'All' ? 'No Cases Yet' : 'No $filter Cases', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
    const SizedBox(height: 6),
    const Text('Record your first veterinary case', style: TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins')),
    if (filter == 'All') ...[
      const SizedBox(height: 24),
      GestureDetector(onTap: onAdd, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Add First Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins'))]),
      )),
    ],
  ]));
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD CASE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddCaseSheet extends StatefulWidget {
  final String vetId, vetName;
  const _AddCaseSheet({required this.vetId, required this.vetName});
  @override
  State<_AddCaseSheet> createState() => _AddCaseSheetState();
}

class _AddCaseSheetState extends State<_AddCaseSheet> {
  final _db          = FirebaseFirestore.instance;
  final _form        = GlobalKey<FormState>();
  final _farmerCtrl  = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _pigNameCtrl = TextEditingController();
  final _pigTagCtrl  = TextEditingController();
  final _condCtrl    = TextEditingController();
  final _treatCtrl   = TextEditingController();
  final _medCtrl     = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String   _status      = 'open';
  bool     _hasFollowUp = false;
  DateTime _followUpDate = DateTime.now().add(const Duration(days: 7));
  bool     _loading     = false;

  static const _conditions = [
    'Vaccination', 'Routine Checkup', 'Respiratory Infection',
    'African Swine Fever (ASF)', 'PRRS', 'Foot & Mouth Disease',
    'Swine Influenza', 'E. coli Infection', 'Ringworm', 'Mange / Scabies',
    'Internal Parasites', 'Diarrhea / Dysentery', 'Anemia', 'Custom...',
  ];
  String _sel = 'Vaccination';

  @override
  void initState() { super.initState(); _condCtrl.text = _sel; }

  @override
  void dispose() {
    _farmerCtrl.dispose(); _phoneCtrl.dispose(); _pigNameCtrl.dispose();
    _pigTagCtrl.dispose(); _condCtrl.dispose(); _treatCtrl.dispose();
    _medCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final vc = VetCase(
        id: '', vetId: widget.vetId, vetName: widget.vetName,
        farmerName:  _farmerCtrl.text.trim(), farmerPhone: _phoneCtrl.text.trim(),
        pigName:     _pigNameCtrl.text.trim(), pigTagId: _pigTagCtrl.text.trim(),
        condition:   _sel == 'Custom...' ? _condCtrl.text.trim() : _sel,
        treatment:   _treatCtrl.text.trim(),
        medication:  _medCtrl.text.trim().isEmpty ? null : _medCtrl.text.trim(),
        notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status:      _status,
        followUpDate: _hasFollowUp ? _followUpDate : null,
        createdAt:   DateTime.now(),
      );
      await _db.collection('vet_cases').add(vc.toMap());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Case saved!', style: TextStyle(fontFamily: 'Poppins'))]),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        // Sheet header
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('New Case Record', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
              Text('Record treatment or diagnosis', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Poppins')),
            ])),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18)),
            ),
          ]),
        ),

        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _form, child: Column(children: [

          _Sec(title: 'Farmer Details', icon: Icons.person_rounded, children: [
            AppTextField(label: 'Farmer Name *', hint: 'e.g. John Kamau', controller: _farmerCtrl, capitalization: TextCapitalization.words, prefixIcon: const Icon(Icons.person_rounded, size: 18, color: AppColors.gray400), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            AppTextField(label: 'Farmer Phone *', hint: 'e.g. 0712345678', controller: _phoneCtrl, keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: AppColors.gray400), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          ]),
          const SizedBox(height: 14),

          _Sec(title: 'Pig Details', icon: Icons.pets_rounded, children: [
            Row(children: [
              Expanded(child: AppTextField(label: 'Pig Name *', hint: 'e.g. Simba', controller: _pigNameCtrl, capitalization: TextCapitalization.words, validator: (v) => v!.trim().isEmpty ? 'Required' : null)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(label: 'Tag / ID', hint: 'e.g. P001', controller: _pigTagCtrl)),
            ]),
          ]),
          const SizedBox(height: 14),

          _Sec(title: 'Condition / Diagnosis', icon: Icons.medical_services_rounded, children: [
            SizedBox(height: 36, child: ListView.builder(
              scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
              itemCount: _conditions.length,
              itemBuilder: (_, i) {
                final cond = _conditions[i];
                final sel  = _sel == cond;
                return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                  onTap: () { setState(() { _sel = cond; if (cond != 'Custom...') _condCtrl.text = cond; else _condCtrl.clear(); }); },
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: sel ? AppColors.primary : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppColors.primary : AppColors.gray200)),
                    child: Text(cond, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: sel ? Colors.white : AppColors.dark)),
                  ),
                ));
              },
            )),
            if (_sel == 'Custom...') ...[
              const SizedBox(height: 12),
              AppTextField(label: 'Describe Condition *', hint: 'Enter diagnosis...', controller: _condCtrl, capitalization: TextCapitalization.sentences, validator: _sel == 'Custom...' ? (v) => v!.trim().isEmpty ? 'Required' : null : null),
            ],
          ]),
          const SizedBox(height: 14),

          _Sec(title: 'Treatment & Medication', icon: Icons.vaccines_rounded, children: [
            AppTextField(label: 'Treatment Given *', hint: 'e.g. Intramuscular injection', controller: _treatCtrl, capitalization: TextCapitalization.sentences, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
            AppTextField(label: 'Medication (optional)', hint: 'e.g. Amoxicillin 500mg for 5 days', controller: _medCtrl, prefixIcon: const Icon(Icons.medication_rounded, size: 18, color: AppColors.gray400)),
          ]),
          const SizedBox(height: 14),

          _Sec(title: 'Case Status', icon: Icons.flag_rounded, children: [
            Row(children: [
              ...[('open', 'Open', AppColors.danger), ('follow_up', 'Follow-up', AppColors.warning), ('resolved', 'Resolved', AppColors.success)].map((s) {
                final active = _status == s.$1;
                return Expanded(child: Padding(padding: EdgeInsets.only(right: s.$1 != 'resolved' ? 8 : 0), child: GestureDetector(
                  onTap: () { setState(() { _status = s.$1; if (_status == 'follow_up') _hasFollowUp = true; }); },
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: active ? s.$3.withValues(alpha: 0.1) : AppColors.gray100, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? s.$3 : AppColors.gray200, width: 1.5)),
                    child: Column(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: active ? s.$3 : AppColors.gray300, shape: BoxShape.circle)),
                      const SizedBox(height: 4),
                      Text(s.$1 == 'open' ? 'Open' : s.$1 == 'follow_up' ? 'Follow-up' : 'Resolved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? s.$3 : AppColors.gray400, fontFamily: 'Poppins')),
                    ]),
                  ),
                )));
              }),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(value: _hasFollowUp, onChanged: (v) => setState(() => _hasFollowUp = v!), activeColor: AppColors.primary),
              const Text('Set Follow-up Date', style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: AppColors.dark, fontWeight: FontWeight.w600)),
            ]),
            if (_hasFollowUp)
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _followUpDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (c, ch) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: ch!));
                  if (d != null) setState(() => _followUpDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.4))),
                  child: Row(children: [
                    const Icon(Icons.event_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 10),
                    Text('${_followUpDate.day}/${_followUpDate.month}/${_followUpDate.year}', style: const TextStyle(fontSize: 14, fontFamily: 'Poppins', color: AppColors.dark, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 14),

          _Sec(title: 'Notes (optional)', icon: Icons.notes_rounded, children: [
            AppTextField(label: '', hint: 'Additional observations or instructions...', controller: _notesCtrl, maxLines: 3),
          ]),
          const SizedBox(height: 24),

          // ✅ BLACK save button
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dark,  // ✅ BLACK
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)), SizedBox(width: 10), Text('Saving...', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))])
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_rounded, size: 18, color: Colors.white), SizedBox(width: 8), Text('Save Case', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))]),
          )),
          const SizedBox(height: 20),
        ])))),
      ]),
    );
  }
}

class _Sec extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  const _Sec({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 15, color: AppColors.primary), const SizedBox(width: 7), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'))]),
      const SizedBox(height: 14),
      ...children,
    ]),
  );
}