// lib/screens/vet/vet_finance_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/mpesa_service.dart';
import '../../widgets/common/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VET SERVICE MODEL
// ─────────────────────────────────────────────────────────────────────────────

class VetService {
  final String  id, vetId, vetName, farmerName, farmerPhone;
  final String  service, description, paymentMethod, status;
  final double  amount;
  final DateTime date, createdAt;

  VetService({
    required this.id, required this.vetId, required this.vetName,
    required this.farmerName, required this.farmerPhone,
    required this.service, required this.description,
    required this.amount, required this.paymentMethod,
    required this.status, required this.date, required this.createdAt,
  });

  factory VetService.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VetService(
      id:            doc.id,
      vetId:         d['vetId']         ?? '',
      vetName:       d['vetName']       ?? '',
      farmerName:    d['farmerName']    ?? '',
      farmerPhone:   d['farmerPhone']   ?? '',
      service:       d['service']       ?? '',
      description:   d['description']  ?? '',
      amount:        (d['amount']  as num?)?.toDouble() ?? 0,
      paymentMethod: d['paymentMethod'] ?? 'Cash',
      status:        d['status']        ?? 'paid',
      date:          (d['date']      as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'vetId': vetId, 'vetName': vetName,
    'farmerName': farmerName, 'farmerPhone': farmerPhone,
    'service': service, 'description': description,
    'amount': amount, 'paymentMethod': paymentMethod, 'status': status,
    'date': Timestamp.fromDate(date), 'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  VET FINANCE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class VetFinanceScreen extends StatelessWidget {
  const VetFinanceScreen({super.key});

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  // ✅ Stream ordered by createdAt — Firestore auto-refreshes UI on new saves
  Stream<List<VetService>> _stream(String vetId) =>
      FirebaseFirestore.instance
          .collection('vet_services')
          .where('vetId', isEqualTo: vetId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map(VetService.fromDoc).toList());

  void _openCharge(BuildContext ctx, String vetId, String vetName) =>
      showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ChargeSheet(vetId: vetId, vetName: vetName),
      );

  Future<void> _delete(BuildContext ctx, String id) async {
    final ok = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Delete Record?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      content: const Text('This will permanently delete this service record.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.gray600)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins'))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok == true) {
      await FirebaseFirestore.instance.collection('vet_services').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final uid  = auth.uid ?? '';
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [

        // ── Dark header ──────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 20),
          decoration: const BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Vet Finance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                Text('Service billing & earnings', style: TextStyle(fontSize: 12, color: Colors.white54, fontFamily: 'Poppins')),
              ])),
              GestureDetector(
                onTap: () => _openCharge(context, uid, user?.fullName ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.success.withValues(alpha: 0.5))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('Charge', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ✅ Live earnings summary from stream
            StreamBuilder<List<VetService>>(
              stream: _stream(uid),
              builder: (_, snap) {
                final svc     = snap.data ?? [];
                final total   = svc.fold(0.0, (s, t) => s + t.amount);
                final now     = DateTime.now();
                final monthly = svc.where((s) => s.date.month == now.month && s.date.year == now.year).fold(0.0, (s, t) => s + t.amount);
                final mpesa   = svc.where((s) => s.paymentMethod.contains('M-PESA')).fold(0.0, (s, t) => s + t.amount);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Total Earnings', style: TextStyle(fontSize: 11, color: Colors.white60, fontFamily: 'Poppins')),
                    Text('KSh ${_fmt(total)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF4ADE80), fontFamily: 'Poppins')),
                    const SizedBox(height: 12),
                    Row(children: [
                      _HStat('This Month', 'KSh ${_fmt(monthly)}', Icons.calendar_month_rounded, const Color(0xFF60A5FA)),
                      const SizedBox(width: 18),
                      _HStat('M-PESA', 'KSh ${_fmt(mpesa)}', Icons.phone_android_rounded, const Color(0xFF4ADE80)),
                      const SizedBox(width: 18),
                      _HStat('Services', '${svc.length}', Icons.receipt_long_rounded, const Color(0xFFF59E0B)),
                    ]),
                  ]),
                );
              },
            ),
          ]),
        ),

        // ── Services list — live stream auto-refreshes ───────────────────
        Expanded(
          child: uid.isEmpty
              ? const Center(child: Text('Not signed in', style: TextStyle(fontFamily: 'Poppins', color: AppColors.gray400)))
              : StreamBuilder<List<VetService>>(
            stream: _stream(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              final svc = snap.data ?? [];

              if (svc.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 90, height: 90, decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(28)), child: const Center(child: Icon(Icons.account_balance_wallet_rounded, size: 44, color: AppColors.success))),
                  const SizedBox(height: 18),
                  const Text('No Services Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                  const SizedBox(height: 6),
                  const Text('Charge for your first veterinary service', style: TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins')),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _openCharge(ctx, uid, auth.user?.fullName ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(14)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Add Service Charge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins'))]),
                    ),
                  ),
                ]));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
                itemCount: svc.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _SvcCard(svc: svc[i], onDelete: () => _delete(ctx, svc[i].id)),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER STAT
// ─────────────────────────────────────────────────────────────────────────────

class _HStat extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _HStat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'Poppins')),
    const SizedBox(height: 3),
    Row(children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins', fontSize: 12))]),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SERVICE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _SvcCard extends StatelessWidget {
  final VetService svc; final VoidCallback onDelete;
  const _SvcCard({required this.svc, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.medical_services_rounded, color: AppColors.success, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(svc.service, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
          const SizedBox(height: 2),
          Text(svc.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins')),
          const SizedBox(height: 3),
          Wrap(spacing: 6, runSpacing: 3, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(20)), child: Text(svc.farmerName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins'))),
            Text('${svc.date.day}/${svc.date.month}/${svc.date.year}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
            if (svc.paymentMethod.contains('M-PESA'))
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Text('M-PESA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50), fontFamily: 'Poppins'))),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+KSh ${svc.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.gray400)),
        ]),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHARGE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ChargeSheet extends StatefulWidget {
  final String vetId, vetName;
  const _ChargeSheet({required this.vetId, required this.vetName});
  @override
  State<_ChargeSheet> createState() => _ChargeSheetState();
}

class _ChargeSheetState extends State<_ChargeSheet> {
  final _db         = FirebaseFirestore.instance;
  final _form       = GlobalKey<FormState>();
  final _farmerCtrl = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();

  String   _service   = 'Consultation';
  DateTime _date      = DateTime.now();
  bool     _loading   = false;
  String   _payMethod = 'cash';

  String? _checkoutId;
  bool    _mpesaInit  = false;
  bool    _mpesaVfy   = false;
  String? _mpesaErr;
  Timer?  _pollTimer;
  int     _pollCount  = 0;

  static const _services = [
    'Consultation', 'Vaccination', 'Treatment', 'Deworming',
    'Surgery', 'Farm Visit', 'Emergency Call', 'Lab Test',
    'Pregnancy Diagnosis', 'AI / Breeding', 'Other',
  ];

  static const _fees = {
    'Consultation': 500, 'Vaccination': 800, 'Treatment': 1500,
    'Deworming': 600, 'Surgery': 5000, 'Farm Visit': 1200,
    'Emergency Call': 2000, 'Lab Test': 1800,
    'Pregnancy Diagnosis': 700, 'AI / Breeding': 1000, 'Other': 500,
  };

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = '${_fees[_service]}';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _farmerCtrl.dispose(); _phoneCtrl.dispose(); _descCtrl.dispose(); _amountCtrl.dispose();
    super.dispose();
  }

  IconData _icon()  => _payMethod == 'mpesa' && !_mpesaInit ? Icons.phone_android_rounded : Icons.check_rounded;
  String   _label() => _payMethod == 'mpesa' && !_mpesaInit ? 'Send STK Push' : _payMethod == 'mpesa' ? 'Resend STK Push' : 'Record Payment';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [

        // ✅ Dark header
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: const BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.medical_services_rounded, color: AppColors.success, size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Charge for Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Colors.white, size: 22)),
          ]),
        ),

        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _form, child: Column(children: [

          // Suggested fee banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(child: Text('Suggested fee for $_service: KSh ${_fees[_service] ?? 500}', style: const TextStyle(fontSize: 11, color: AppColors.success, fontFamily: 'Poppins'))),
            ]),
          ),
          const SizedBox(height: 14),

          // Service type chips
          _FF(label: 'Service Type', child: SizedBox(height: 36, child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _services.length,
            itemBuilder: (_, i) {
              final svc = _services[i];
              final sel = _service == svc;
              return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                onTap: () => setState(() { _service = svc; _amountCtrl.text = '${_fees[svc] ?? 500}'; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: sel ? AppColors.success : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? AppColors.success : AppColors.gray200)),
                  child: Text(svc, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: sel ? Colors.white : AppColors.dark)),
                ),
              ));
            },
          ))),
          const SizedBox(height: 12),

          _FF(label: 'Farmer Name *', child: TextFormField(
            controller: _farmerCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: _dec('e.g. John Kamau', Icons.person_rounded),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          )),
          const SizedBox(height: 12),

          // ✅ KSh prefix
          _FF(label: 'Amount (KSh) *', child: TextFormField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Service fee',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
              prefixIcon: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
                child: const Text('KSh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'Poppins')),
              ),
              filled: true, fillColor: AppColors.offWhite,
              border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.success, width: 1.5)),
              errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Enter valid amount';
              return null;
            },
          )),
          const SizedBox(height: 12),

          _FF(label: 'Description', child: TextFormField(
            controller: _descCtrl,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: _dec('e.g. Treated Simba for respiratory infection', Icons.description_rounded),
          )),
          const SizedBox(height: 12),

          // Date
          _FF(label: 'Date', child: GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now(), builder: (c, ch) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.success)), child: ch!));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200, width: 1.5)),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.gray400),
                const SizedBox(width: 10),
                Text('${_date.day}/${_date.month}/${_date.year}', style: const TextStyle(fontSize: 14, fontFamily: 'Poppins', color: AppColors.dark)),
                const Spacer(),
                const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ]),
            ),
          )),
          const SizedBox(height: 12),

          // Payment method
          _FF(label: 'Payment Method', child: Row(children: [
            Expanded(child: _PayBtn(label: 'Cash', icon: Icons.payments_rounded, sel: _payMethod == 'cash', color: AppColors.success, onTap: () => setState(() { _payMethod = 'cash'; _mpesaInit = false; _mpesaErr = null; }))),
            const SizedBox(width: 10),
            Expanded(child: _PayBtn(label: 'M-PESA', icon: Icons.phone_android_rounded, sel: _payMethod == 'mpesa', color: const Color(0xFF4CAF50), onTap: () => setState(() => _payMethod = 'mpesa'))),
          ])),
          const SizedBox(height: 12),

          if (_payMethod == 'mpesa') ...[
            _FF(label: 'Farmer Phone *', child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _dec('e.g. 0712345678', Icons.phone_rounded),
              validator: (v) { if (_payMethod == 'mpesa' && (v == null || v.trim().isEmpty)) return 'Phone required for M-PESA'; return null; },
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3))),
              child: const Column(children: [
                Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4CAF50)), SizedBox(width: 8), Text('M-PESA STK Flow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50), fontFamily: 'Poppins'))]),
                SizedBox(height: 6),
                Text('1. Enter phone & amount\n2. Tap "Send STK Push"\n3. Farmer enters M-PESA PIN\n4. Payment verified & service recorded', style: TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.5)),
              ]),
            ),
            const SizedBox(height: 8),

            if (_mpesaInit && _checkoutId != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                child: Column(children: [
                  Row(children: [
                    const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('STK Push Sent!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins'))),
                    if (_mpesaVfy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Ask farmer to enter M-PESA PIN. Auto-verified.', style: TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: _mpesaVfy ? null : () => _checkStatus(auto: false),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('Check Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins'))])),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: GestureDetector(
                      onTap: () => _record('M-PESA (confirmed)'),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_rounded, size: 14, color: AppColors.success), SizedBox(width: 6), Text('Mark Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'Poppins'))])),
                    )),
                  ]),
                ]),
              ),
              const SizedBox(height: 8),
            ],

            if (_mpesaErr != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger), const SizedBox(width: 8), Expanded(child: Text(_mpesaErr!, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontFamily: 'Poppins')))]),
              ),
            const SizedBox(height: 12),
          ],

          // ✅ Black save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text('Processing...', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_icon(), size: 18, color: Colors.white), const SizedBox(width: 8), Text(_label(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))]),
            ),
          ),
        ])))),
      ]),
    );
  }

  Future<void> _handleSave() async {
    if (!_form.currentState!.validate()) return;
    if (_payMethod == 'cash') { await _record('Cash'); }
    else { await _sendSTK(); }
  }

  Future<void> _sendSTK() async {
    setState(() { _loading = true; _mpesaErr = null; });
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final result = await MpesaService.stkPush(phoneNumber: _phoneCtrl.text.trim(), amount: amount, accountReference: 'VetServices', transactionDesc: _service);
      if (!mounted) return;
      if (result.success && result.checkoutRequestId != null) {
        setState(() { _checkoutId = result.checkoutRequestId; _mpesaInit = true; _mpesaErr = null; _pollCount = 0; });
        _startPolling();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('M-PESA prompt sent!', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Color(0xFF4CAF50), behavior: SnackBarBehavior.floating));
      } else {
        setState(() => _mpesaErr = result.errorMessage ?? 'STK push failed.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_pollCount >= 10) {
        _pollTimer?.cancel();
        if (mounted) setState(() { _mpesaVfy = false; _mpesaErr = 'Timeout. Tap "Mark Paid" if farmer already paid.'; });
        return;
      }
      _pollCount++;
      await _checkStatus(auto: true);
    });
  }

  Future<void> _checkStatus({bool auto = false}) async {
    if (_checkoutId == null) return;
    if (mounted) setState(() => _mpesaVfy = true);
    try {
      final r = await MpesaService.queryStatus(checkoutRequestId: _checkoutId!);
      if (!mounted) return;
      if (r.paid) {
        _pollTimer?.cancel();
        setState(() => _mpesaVfy = false);
        await _record('M-PESA');
      } else if (!r.pending) {
        _pollTimer?.cancel();
        setState(() { _mpesaVfy = false; _mpesaErr = r.resultDesc ?? 'Payment not completed.'; _mpesaInit = false; });
      } else {
        if (!auto) setState(() => _mpesaVfy = false);
      }
    } catch (_) {
      if (mounted) setState(() => _mpesaVfy = false);
    }
  }

  /// ✅ Saves to BOTH vet_services (vet dashboard) AND transactions (shared finance ledger)
  Future<void> _record(String paymentMethod) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    _pollTimer?.cancel();
    try {
      final description = _descCtrl.text.trim().isEmpty
          ? '$_service for ${_farmerCtrl.text.trim()}'
          : _descCtrl.text.trim();
      final amount = double.parse(_amountCtrl.text.trim());

      final svc = VetService(
        id: '', vetId: widget.vetId, vetName: widget.vetName,
        farmerName:    _farmerCtrl.text.trim(),
        farmerPhone:   _phoneCtrl.text.trim(),
        service:       _service,
        description:   description,
        amount:        amount,
        paymentMethod: paymentMethod,
        status:        'paid',
        date:          _date,
        createdAt:     DateTime.now(),
      );

      // ✅ 1. Save to vet_services collection (vet dashboard list)
      await _db.collection('vet_services').add(svc.toMap());

      // ✅ 2. Also save to transactions collection (same as farmer finance screen)
      //       so it appears in the shared finance ledger and FinanceProvider picks it up
      final tx = TransactionModel(
        id:          '',
        userId:      widget.vetId,
        type:        TransactionType.sale,
        category:    'Vet Service',
        description: '$_service – ${_farmerCtrl.text.trim()}${_descCtrl.text.trim().isNotEmpty ? " (${_descCtrl.text.trim()})" : ""}',
        amount:      amount,
        date:        _date,
        createdAt:   DateTime.now(),
        receiptUrl:  paymentMethod,   // reusing receiptUrl field for payment method
      );
      await _db.collection('transactions').add(tx.toMap());

      if (mounted) {
        // ✅ 3. Force-refresh FinanceProvider so earnings update immediately
        context.read<FinanceProvider>().forceInit(widget.vetId);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('KSh ${svc.amount.toStringAsFixed(0)} charged to ${svc.farmerName} via $paymentMethod!', style: const TextStyle(fontFamily: 'Poppins'))),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e', style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
    prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
    filled: true, fillColor: AppColors.offWhite,
    border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.success, width: 1.5)),
    errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _FF extends StatelessWidget {
  final String label; final Widget child;
  const _FF({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (label.isNotEmpty) ...[Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'Poppins')), const SizedBox(height: 6)],
    child,
  ]);
}

class _PayBtn extends StatelessWidget {
  final String label; final IconData icon; final bool sel; final Color color; final VoidCallback onTap;
  const _PayBtn({required this.label, required this.icon, required this.sel, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: sel ? color.withValues(alpha: 0.1) : AppColors.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? color : AppColors.gray200, width: sel ? 2 : 1.5)),
      child: Column(children: [Icon(icon, size: 22, color: sel ? color : AppColors.gray400), const SizedBox(height: 5), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? color : AppColors.gray600, fontFamily: 'Poppins'))]),
    ),
  );
}