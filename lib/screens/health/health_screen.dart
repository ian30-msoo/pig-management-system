// lib/screens/health/health_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/pig_model.dart';
import '../../utils/constants.dart';
import '../../widgets/common/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HEALTH SCREEN
//  Loads health records from every pig's subcollection and merges them.
//  No collectionGroup query = no index needed.
// ─────────────────────────────────────────────────────────────────────────────

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  List<HealthRecord> _records  = [];
  bool               _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  /// Load health records for every active pig and merge into one sorted list.
  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final provider = context.read<PigProvider>();
    final pigs     = provider.activePigs;

    final results = await Future.wait(
      pigs.map((p) => provider.getPigHealth(p.id)),
    );

    final all = results.expand((list) => list).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    if (mounted) setState(() { _records = all; _loading = false; });
  }

  Color _statusColor(String s) =>
      s == 'recovered' ? AppColors.success :
      s == 'critical'  ? AppColors.danger  : AppColors.warning;

  Color _statusBg(String s) =>
      s == 'recovered' ? AppColors.successBg :
      s == 'critical'  ? AppColors.dangerBg  : AppColors.warningBg;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Vaccination': return Icons.vaccines_rounded;
      case 'Treatment':   return Icons.medical_services_rounded;
      case 'Deworming':   return Icons.pest_control_rounded;
      default:            return Icons.monitor_heart_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Vaccination': return AppColors.blue;
      case 'Treatment':   return AppColors.danger;
      case 'Deworming':   return AppColors.warning;
      default:            return AppColors.success;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'Vaccination': return AppColors.blueBg;
      case 'Treatment':   return AppColors.dangerBg;
      case 'Deworming':   return AppColors.warningBg;
      default:            return AppColors.successBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-load if pig list changes (e.g. pig added)
    context.watch<PigProvider>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Health Records',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white)),
          if (!_loading)
            Text('${_records.length} record${_records.length != 1 ? "s" : ""}',
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70, fontFamily: 'Poppins')),
        ]),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAll,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () async {
              final pigs = context.read<PigProvider>().activePigs;
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AddHealthSheet(
                  pigs: pigs.map((p) => {'id': p.id, 'name': p.name}).toList(),
                  onSaved: _loadAll,
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text('Loading health records...',
                style: TextStyle(
                    color: AppColors.gray400,
                    fontFamily: 'Poppins',
                    fontSize: 13)),
          ]))
          : _records.isEmpty
          ? _EmptyHealth(
        onAdd: () async {
          final pigs = context.read<PigProvider>().activePigs;
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddHealthSheet(
              pigs: pigs
                  .map((p) => {'id': p.id, 'name': p.name})
                  .toList(),
              onSaved: _loadAll,
            ),
          );
        },
      )
          : RefreshIndicator(
        onRefresh: _loadAll,
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
          itemCount: _records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final h = _records[i];
            return _HealthCard(
              record: h,
              typeIcon:   _typeIcon(h.type),
              typeColor:  _typeColor(h.type),
              typeBg:     _typeBg(h.type),
              statusColor: _statusColor(h.status),
              statusBg:    _statusBg(h.status),
              onDelete: () async {
                final ok = await context
                    .read<PigProvider>()
                    .deleteHealthRecord(h.pigId, h.id);
                if (ok) _loadAll();
              },
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEALTH CARD
// ─────────────────────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  final HealthRecord record;
  final IconData  typeIcon;
  final Color     typeColor, typeBg, statusColor, statusBg;
  final VoidCallback onDelete;

  const _HealthCard({
    required this.record,
    required this.typeIcon,
    required this.typeColor,
    required this.typeBg,
    required this.statusColor,
    required this.statusBg,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = record;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Top row: type badge + date + delete ──────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: typeBg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(typeIcon, size: 12, color: typeColor),
                const SizedBox(width: 4),
                Text(h.type,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                        fontFamily: 'Poppins')),
              ]),
            ),
            const Spacer(),
            Text(
                '${h.date.day}/${h.date.month}/${h.date.year}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                    fontFamily: 'Poppins')),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.gray400),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Middle: pig name + status badge ─────────────────────────
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(typeIcon, size: 18, color: statusColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.pigName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark,
                            fontFamily: 'Poppins')),
                    Text(h.condition,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                            fontFamily: 'Poppins')),
                  ]),
            ),
            StatusBadge(
                label: h.status[0].toUpperCase() + h.status.substring(1),
                color: statusColor,
                bgColor: statusBg),
          ]),

          // ── Details ──────────────────────────────────────────────────
          if (h.treatment != null || h.temperature != null ||
              h.vetName != null || h.notes != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (h.treatment != null)
                  _DetailChip(
                      icon: Icons.medical_services_rounded,
                      label: h.treatment!),
                if (h.temperature != null)
                  _DetailChip(
                      icon: Icons.thermostat_rounded,
                      label: '${h.temperature}°C'),
                if (h.vetName != null)
                  _DetailChip(
                      icon: Icons.person_rounded,
                      label: h.vetName!),
              ],
            ),
            if (h.notes != null) ...[
              const SizedBox(height: 6),
              Text(h.notes!,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ]),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppColors.gray400),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray600,
              fontFamily: 'Poppins')),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHealth extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHealth({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Center(
            child: Icon(Icons.favorite_rounded,
                size: 44, color: AppColors.danger)),
      ),
      const SizedBox(height: 18),
      const Text('No Health Records',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.dark,
              fontFamily: 'Poppins')),
      const SizedBox(height: 6),
      const Text('Start tracking pig health and vaccinations',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.gray400,
              fontFamily: 'Poppins')),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(14)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Add Health Record',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Poppins')),
          ]),
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD HEALTH SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddHealthSheet extends StatefulWidget {
  final List<Map<String, String>> pigs;
  final VoidCallback onSaved;
  const _AddHealthSheet({required this.pigs, required this.onSaved});

  @override
  State<_AddHealthSheet> createState() => _AddHealthSheetState();
}

class _AddHealthSheetState extends State<_AddHealthSheet> {
  final _form      = GlobalKey<FormState>();
  final _treatment = TextEditingController();
  final _vet       = TextEditingController();
  final _temp      = TextEditingController();
  final _notes     = TextEditingController();

  String? _pigId, _pigName;
  String  _type      = 'Checkup';
  String  _condition = AppConstants.healthConditions.first;
  String  _status    = 'ongoing';
  bool    _loading   = false;

  @override
  void dispose() {
    _treatment.dispose();
    _vet.dispose();
    _temp.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.danger, Color(0xFFB91C1C)]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Row(children: [
            const Text('Add Health Record',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins')),
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

                    // Pig selector
                    _FormLabel('Select Pig'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _pigId,
                      hint: const Text('Choose pig...',
                          style: TextStyle(fontFamily: 'Poppins')),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.savings_rounded,
                              size: 18, color: AppColors.gray400)),
                      items: widget.pigs
                          .map((p) => DropdownMenuItem(
                        value: p['id'],
                        child: Text(p['name']!,
                            style: const TextStyle(
                                fontFamily: 'Poppins')),
                      ))
                          .toList(),
                      validator: (v) => v == null ? 'Select a pig' : null,
                      onChanged: (v) => setState(() {
                        _pigId   = v;
                        _pigName = widget.pigs
                            .firstWhere((p) => p['id'] == v)['name'];
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Record type chips
                    _FormLabel('Record Type'),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Checkup', 'Vaccination', 'Treatment', 'Deworming']
                          .map((t) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: t != 'Deworming' ? 6 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _type = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: _type == t
                                    ? AppColors.primaryBg
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _type == t
                                        ? AppColors.primary
                                        : AppColors.gray200,
                                    width: 1.5),
                              ),
                              child: Text(t,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _type == t
                                          ? AppColors.primary
                                          : AppColors.gray600,
                                      fontFamily: 'Poppins')),
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),

                    // Condition dropdown
                    _FormLabel('Condition / Diagnosis'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _condition,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.medical_information_rounded,
                              size: 18, color: AppColors.gray400)),
                      items: AppConstants.healthConditions
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 13)),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _condition = v!),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Treatment Given',
                      hint: 'e.g. Amoxicillin 500mg, 3 days',
                      controller: _treatment,
                      capitalization: TextCapitalization.sentences,
                    ),
                    AppTextField(
                      label: 'Veterinarian (optional)',
                      hint: 'e.g. Dr. Kamau',
                      controller: _vet,
                      prefixIcon: const Icon(Icons.person_rounded,
                          size: 18, color: AppColors.gray400),
                    ),
                    AppTextField(
                      label: 'Temperature °C (optional)',
                      hint: 'e.g. 38.5',
                      controller: _temp,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.thermostat_rounded,
                          size: 18, color: AppColors.gray400),
                    ),

                    // Status chips
                    _FormLabel('Status'),
                    const SizedBox(height: 8),
                    Row(
                      children: ['ongoing', 'recovered', 'critical']
                          .map((s) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: s != 'critical' ? 6 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _status = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: _status == s
                                    ? (s == 'recovered'
                                    ? AppColors.successBg
                                    : s == 'critical'
                                    ? AppColors.dangerBg
                                    : AppColors.warningBg)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _status == s
                                        ? (s == 'recovered'
                                        ? AppColors.success
                                        : s == 'critical'
                                        ? AppColors.danger
                                        : AppColors.warning)
                                        : AppColors.gray200,
                                    width: 1.5),
                              ),
                              child: Text(
                                  s[0].toUpperCase() + s.substring(1),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _status == s
                                          ? (s == 'recovered'
                                          ? AppColors.success
                                          : s == 'critical'
                                          ? AppColors.danger
                                          : AppColors.warning)
                                          : AppColors.gray600,
                                      fontFamily: 'Poppins')),
                            ),
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Notes (optional)',
                      hint: 'Additional observations...',
                      controller: _notes,
                      maxLines: 2,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save Health Record',
                  icon: Icons.check_rounded,
                  loading: _loading,
                  color: AppColors.danger,
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

    final now = DateTime.now();
    final record = HealthRecord(
      id:           '',
      pigId:        _pigId!,
      pigName:      _pigName!,
      type:         _type,
      condition:    _condition,
      treatment:    _treatment.text.trim().isEmpty ? null : _treatment.text.trim(),
      veterinarian: _vet.text.trim().isEmpty ? null : _vet.text.trim(),
      temperature:  _temp.text.trim().isEmpty
          ? null : double.tryParse(_temp.text.trim()),
      status:       _status,
      notes:        _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      date:         now,
      createdAt:    now,
    );

    await context.read<PigProvider>().addHealthRecord(_pigId!, record);
    if (mounted) {
      Navigator.pop(context);
      widget.onSaved(); // refresh the list
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray600,
            fontFamily: 'Poppins')),
  );
}