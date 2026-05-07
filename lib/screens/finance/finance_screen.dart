// lib/screens/finance/finance_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../models/pig_model.dart';
import '../../services/mpesa_service.dart';
import '../../widgets/common/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FINANCE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});
  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    // ✅ Force re-init on every screen visit to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().uid;
      if (uid != null) {
        context.read<FinanceProvider>().forceInit(uid);
      }
    });
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final uid = context.read<AuthProvider>().uid;
    if (uid != null) context.read<FinanceProvider>().forceInit(uid);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _refreshing = false);
  }

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final mq      = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        // ── Header ───────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.only(top: mq.padding.top + 10, left: 20, right: 20, bottom: 22),
          decoration: const BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Financial Records', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
              GestureDetector(
                onTap: _refresh,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: _refreshing
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Net Profit (All Time)', style: TextStyle(fontSize: 11, color: Colors.white60, fontFamily: 'Poppins')),
                Text(
                  'KSh ${_fmt(finance.profit)}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Poppins',
                      color: finance.profit >= 0 ? const Color(0xFF4ADE80) : const Color(0xFFF87171)),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _HeaderStat('Income',     'KSh ${_fmt(finance.totalIncome)}',   Icons.trending_up_rounded,   const Color(0xFF4ADE80)),
                  const SizedBox(width: 18),
                  _HeaderStat('Expenses',   'KSh ${_fmt(finance.totalExpenses)}', Icons.trending_down_rounded, const Color(0xFFF87171)),
                  const SizedBox(width: 18),
                  _HeaderStat('This Month', 'KSh ${_fmt(finance.monthlyIncome - finance.monthlyExpenses)}', Icons.calendar_month_rounded, const Color(0xFF60A5FA)),
                ]),
              ]),
            ),
          ]),
        ),

        // ── Body ─────────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              children: [
                Row(children: [
                  Expanded(child: StatCard(label: 'Sales This Month', value: 'KSh ${_fmt(finance.monthlyIncome)}', icon: Icons.trending_up_rounded, color: AppColors.success, bgColor: AppColors.successBg)),
                  const SizedBox(width: 10),
                  Expanded(child: StatCard(label: 'Expenses', value: 'KSh ${_fmt(finance.monthlyExpenses)}', icon: Icons.trending_down_rounded, color: AppColors.danger, bgColor: AppColors.dangerBg)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _openAddSheet(TransactionType.sale),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Record Sale', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _openAddSheet(TransactionType.expense),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Expense', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  const Expanded(child: SectionHeader(title: 'Recent Transactions')),
                  if (finance.transactions.isNotEmpty)
                    Text('${finance.transactions.length} records', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                ]),
                const SizedBox(height: 10),
                if (finance.transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Column(children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppColors.gray200),
                      SizedBox(height: 12),
                      Text('No Transactions Yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
                      SizedBox(height: 4),
                      Text('Start recording your sales and expenses', style: TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
                    ]),
                  )
                else
                  ...finance.transactions.map((t) => _TransactionCard(tx: t, onDelete: () => _deleteTransaction(t))),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _openAddSheet(TransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTransactionSheet(initialType: type),
    ).then((_) {
      // ✅ Auto-refresh after sheet closes
      final uid = context.read<AuthProvider>().uid;
      if (uid != null && mounted) context.read<FinanceProvider>().forceInit(uid);
    });
  }

  Future<void> _deleteTransaction(TransactionModel t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction?', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        content: Text('Delete "${t.description}" (KSh ${t.amount.toStringAsFixed(0)})?', style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: AppColors.danger), child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<FinanceProvider>().deleteTransaction(t.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER STAT
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _HeaderStat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54, fontFamily: 'Poppins')),
    const SizedBox(height: 3),
    Row(children: [Icon(icon, size: 13, color: color), const SizedBox(width: 4), Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins', fontSize: 12))]),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  TRANSACTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final TransactionModel tx; final VoidCallback onDelete;
  const _TransactionCard({required this.tx, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == TransactionType.expense;
    final color     = isExpense ? AppColors.danger : AppColors.success;
    final bgColor   = isExpense ? AppColors.dangerBg : AppColors.successBg;
    final payMethod = tx.receiptUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(13)), child: Icon(isExpense ? Icons.trending_down_rounded : Icons.trending_up_rounded, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
            const SizedBox(height: 3),
            Wrap(spacing: 6, runSpacing: 4, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(tx.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins'))),
              Text('${tx.date.day}/${tx.date.month}/${tx.date.year}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
              if (tx.pigName != null) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.pets_rounded, size: 10, color: AppColors.gray400), const SizedBox(width: 3), Text(tx.pigName!, style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins'))]),
              if (payMethod != null && payMethod.isNotEmpty && payMethod != 'Cash')
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(payMethod.contains('M-PESA') ? 'M-PESA' : payMethod, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50), fontFamily: 'Poppins'))),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${isExpense ? "-" : "+"}KSh ${tx.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.gray400)),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD TRANSACTION SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  const _AddTransactionSheet({required this.initialType});
  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  late TransactionType _type;
  final _form       = GlobalKey<FormState>();
  final _descCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  String _category  = 'General';
  DateTime _date    = DateTime.now();
  bool _loading     = false;
  String _payMethod = 'cash';

  String?  _checkoutRequestId;
  bool     _mpesaInitiated = false;
  bool     _mpesaVerifying = false;
  String?  _mpesaError;
  Timer?   _pollTimer;
  int      _pollCount = 0;

  final _salesCategories   = ['Pig Sale', 'Piglet Sale', 'Sow Sale', 'Boar Sale', 'Other Income'];
  final _expenseCategories = ['Feed Purchase', 'Veterinary', 'Medication', 'Equipment', 'Labor', 'Transport', 'Utilities', 'Other'];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == TransactionType.expense ? 'Feed Purchase' : 'Pig Sale';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _descCtrl.dispose(); _amountCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == TransactionType.expense ? _expenseCategories : _salesCategories;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        // ✅ Dark header
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: const BoxDecoration(color: AppColors.dark, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: (_type == TransactionType.expense ? AppColors.danger : AppColors.success).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(_type == TransactionType.expense ? Icons.trending_down_rounded : Icons.trending_up_rounded, color: _type == TransactionType.expense ? AppColors.danger : AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_type == TransactionType.expense ? 'Add Expense' : 'Record Sale', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(key: _form, child: Column(children: [

            _Field(label: 'Description *', child: TextFormField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _dec('e.g. purchased feeds', Icons.description_rounded),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            )),
            const SizedBox(height: 12),

            // ✅ KSh prefix
            _Field(label: 'Amount (KSh) *', child: TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. 25000',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
                prefixIcon: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(6)),
                  child: const Text('KSh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Poppins')),
                ),
                filled: true, fillColor: AppColors.offWhite,
                border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            )),
            const SizedBox(height: 12),

            _Field(label: 'Category', child: DropdownButtonFormField<String>(
              value: _categories.contains(_category) ? _category : _categories.first,
              decoration: _dec('Category', Icons.category_rounded),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.dark),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            )),
            const SizedBox(height: 12),

            _Field(label: 'Date', child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now(), builder: (c, ch) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: ch!));
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
                  const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                ]),
              ),
            )),
            const SizedBox(height: 12),

            // ✅ Payment method (sales only)
            if (_type != TransactionType.expense) ...[
              _Field(label: 'Payment Method', child: Row(children: [
                Expanded(child: _PayMethodBtn(label: 'Cash', icon: Icons.payments_rounded, selected: _payMethod == 'cash', color: AppColors.success, onTap: () => setState(() { _payMethod = 'cash'; _mpesaInitiated = false; _mpesaError = null; }))),
                const SizedBox(width: 10),
                Expanded(child: _PayMethodBtn(label: 'M-PESA', icon: Icons.phone_android_rounded, selected: _payMethod == 'mpesa', color: const Color(0xFF4CAF50), onTap: () => setState(() => _payMethod = 'mpesa'))),
              ])),
              const SizedBox(height: 12),

              if (_payMethod == 'mpesa') ...[
                _Field(label: 'Customer Phone *', child: TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  decoration: _dec('e.g. 0712345678', Icons.phone_rounded),
                  validator: _payMethod == 'mpesa' ? (v) { if (v == null || v.trim().isEmpty) return 'Phone required for M-PESA'; return null; } : null,
                )),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3))),
                  child: const Column(children: [
                    Row(children: [Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF4CAF50)), SizedBox(width: 8), Text('M-PESA Flow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50), fontFamily: 'Poppins'))]),
                    SizedBox(height: 6),
                    Text('1. Enter phone & amount\n2. Tap "Send STK Push"\n3. Customer enters M-PESA PIN\n4. Payment verified and sale auto-recorded', style: TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 8),

                if (_mpesaInitiated && _checkoutRequestId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                    child: Column(children: [
                      Row(children: [
                        const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('STK Push Sent!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins'))),
                        if (_mpesaVerifying) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      ]),
                      const SizedBox(height: 6),
                      const Text('Ask customer to enter their M-PESA PIN. Payment verified automatically.', style: TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.4)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: _mpesaVerifying ? null : _checkPaymentStatus,
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('Check Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins'))])),
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: GestureDetector(
                          onTap: _recordCashFallback,
                          child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_rounded, size: 14, color: AppColors.success), SizedBox(width: 6), Text('Mark as Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'Poppins'))])),
                        )),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 8),
                ],

                if (_mpesaError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
                    child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger), const SizedBox(width: 8), Expanded(child: Text(_mpesaError!, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontFamily: 'Poppins')))]),
                  ),
                const SizedBox(height: 12),
              ],
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleSave,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.dark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _loading
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text('Processing...', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))])
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_getSaveIcon(), size: 18, color: Colors.white), const SizedBox(width: 8), Text(_getSaveLabel(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))]),
              ),
            ),
          ])),
        )),
      ]),
    );
  }

  IconData _getSaveIcon() {
    if (_type == TransactionType.expense) return Icons.save_rounded;
    if (_payMethod == 'mpesa' && !_mpesaInitiated) return Icons.phone_android_rounded;
    return Icons.check_rounded;
  }

  String _getSaveLabel() {
    if (_type == TransactionType.expense) return 'Save Expense';
    if (_payMethod == 'mpesa' && !_mpesaInitiated) return 'Send STK Push';
    if (_payMethod == 'mpesa' && _mpesaInitiated) return 'Resend STK Push';
    return 'Save Sale';
  }

  Future<void> _handleSave() async {
    if (!_form.currentState!.validate()) return;
    if (_type == TransactionType.expense || _payMethod == 'cash') {
      await _saveDirect();
    } else {
      await _sendMpesaSTK();
    }
  }

  Future<void> _saveDirect() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid  = auth.uid;
      if (uid == null) throw Exception('Not signed in');

      final tx = TransactionModel(
        id: '', userId: uid, type: _type, category: _category,
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        date: _date, createdAt: DateTime.now(),
        receiptUrl: _payMethod == 'cash' ? 'Cash' : null,
      );

      // ✅ Save via provider (which saves to Firestore and stream auto-updates)
      final ok = await context.read<FinanceProvider>().addTransaction(tx);
      if (!mounted) return;

      if (ok) {
        // ✅ Force refresh so list updates immediately
        context.read<FinanceProvider>().forceInit(uid);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${_type == TransactionType.expense ? "Expense" : "Sale"} recorded!', style: const TextStyle(fontFamily: 'Poppins')),
          ]),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save. Please try again.'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMpesaSTK() async {
    setState(() { _loading = true; _mpesaError = null; });
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final result = await MpesaService.stkPush(phoneNumber: _phoneCtrl.text.trim(), amount: amount, accountReference: 'PigTrack', transactionDesc: _category);
      if (!mounted) return;
      if (result.success && result.checkoutRequestId != null) {
        setState(() { _checkoutRequestId = result.checkoutRequestId; _mpesaInitiated = true; _mpesaError = null; _pollCount = 0; });
        _startPolling();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('M-PESA prompt sent!', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Color(0xFF4CAF50), behavior: SnackBarBehavior.floating));
      } else {
        setState(() => _mpesaError = result.errorMessage ?? 'STK push failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_pollCount >= 6) {
        _pollTimer?.cancel();
        if (mounted) setState(() { _mpesaVerifying = false; _mpesaError = 'Timeout. Tap "Mark as Paid" if customer paid.'; });
        return;
      }
      _pollCount++;
      await _checkPaymentStatus(auto: true);
    });
  }

  Future<void> _checkPaymentStatus({bool auto = false}) async {
    if (_checkoutRequestId == null) return;
    if (mounted) setState(() => _mpesaVerifying = true);
    try {
      final result = await MpesaService.queryStatus(checkoutRequestId: _checkoutRequestId!);
      if (!mounted) return;
      if (result.paid) {
        _pollTimer?.cancel();
        setState(() => _mpesaVerifying = false);
        await _recordPaidTransaction(paymentMethod: 'M-PESA');
      } else if (!result.pending) {
        _pollTimer?.cancel();
        setState(() { _mpesaVerifying = false; _mpesaError = result.resultDesc ?? 'Payment not completed.'; _mpesaInitiated = false; });
      } else {
        if (!auto) setState(() => _mpesaVerifying = false);
      }
    } catch (_) {
      if (mounted) setState(() => _mpesaVerifying = false);
    }
  }

  Future<void> _recordCashFallback() async => _recordPaidTransaction(paymentMethod: 'M-PESA (confirmed)');

  Future<void> _recordPaidTransaction({required String paymentMethod}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    _pollTimer?.cancel();
    try {
      final auth = context.read<AuthProvider>();
      final uid  = auth.uid;
      if (uid == null) throw Exception('Not signed in');

      final tx = TransactionModel(
        id: '', userId: uid, type: _type, category: _category,
        description: _descCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        date: _date, createdAt: DateTime.now(),
        receiptUrl: paymentMethod,
      );

      final ok = await context.read<FinanceProvider>().addTransaction(tx);
      if (!mounted) return;

      if (ok) {
        context.read<FinanceProvider>().forceInit(uid); // ✅ Force refresh
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Text('Sale via $paymentMethod recorded!', style: const TextStyle(fontFamily: 'Poppins'))]),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
    prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
    filled: true, fillColor: AppColors.offWhite,
    border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    errorBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _Field extends StatelessWidget {
  final String label; final Widget child;
  const _Field({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    if (label.isNotEmpty) ...[Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'Poppins')), const SizedBox(height: 6)],
    child,
  ]);
}

class _PayMethodBtn extends StatelessWidget {
  final String label; final IconData icon; final bool selected; final Color color; final VoidCallback onTap;
  const _PayMethodBtn({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: selected ? color.withValues(alpha: 0.1) : AppColors.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? color : AppColors.gray200, width: selected ? 2 : 1.5)),
      child: Column(children: [Icon(icon, size: 22, color: selected ? color : AppColors.gray400), const SizedBox(height: 5), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? color : AppColors.gray600, fontFamily: 'Poppins'))]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SELL PIG SHEET (called from pigs_screen)
// ─────────────────────────────────────────────────────────────────────────────

class SellPigSheet extends StatefulWidget {
  final String pigId, pigName, pigTagId;
  final double currentWeight;
  final VoidCallback onSold;
  const SellPigSheet({super.key, required this.pigId, required this.pigName, required this.pigTagId, required this.currentWeight, required this.onSold});
  @override
  State<SellPigSheet> createState() => _SellPigSheetState();
}

class _SellPigSheetState extends State<SellPigSheet> {
  final _form = GlobalKey<FormState>();
  final _buyerCtrl   = TextEditingController();
  final _amountCtrl  = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _weightCtrl  = TextEditingController();
  bool _loading = false;
  String _payMethod = 'cash';
  String? _checkoutRequestId; bool _mpesaInitiated = false, _mpesaVerifying = false;
  String? _mpesaError; Timer? _pollTimer; int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _weightCtrl.text = widget.currentWeight.toStringAsFixed(1);
    _amountCtrl.text = (widget.currentWeight * 270).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _buyerCtrl.dispose(); _amountCtrl.dispose(); _phoneCtrl.dispose(); _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle), child: const Icon(Icons.sell_rounded, color: Colors.white, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sell ${widget.pigName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
              Text('${widget.pigTagId} · ${widget.currentWeight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Poppins')),
            ])),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: Colors.white)),
          ]),
        ),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _form, child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
            child: Row(children: [const Icon(Icons.lightbulb_outlined, size: 16, color: AppColors.success), const SizedBox(width: 8), Expanded(child: Text('Suggested: KSh ${(widget.currentWeight * 270).toStringAsFixed(0)} (KES 270/kg · Nairobi market Apr 2026)', style: const TextStyle(fontSize: 11, color: AppColors.success, fontFamily: 'Poppins', height: 1.4)))]),
          ),
          const SizedBox(height: 14),

          _Field(label: 'Buyer Name *', child: TextFormField(controller: _buyerCtrl, textCapitalization: TextCapitalization.words, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14), decoration: _dec2('e.g. John Kamau', Icons.person_rounded), validator: (v) => v!.trim().isEmpty ? 'Required' : null)),
          const SizedBox(height: 12),

          _Field(label: 'Sale Amount (KSh) *', child: TextFormField(
            controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Sale price', hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
              prefixIcon: Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(6)), child: const Text('KSh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Poppins'))),
              filled: true, fillColor: AppColors.offWhite,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            validator: (v) { if (v == null || v.trim().isEmpty) return 'Required'; final n = double.tryParse(v.trim()); if (n == null || n <= 0) return 'Enter a valid amount'; return null; },
          )),
          const SizedBox(height: 12),

          _Field(label: 'Final Weight at Sale (kg)', child: TextFormField(controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14), decoration: _dec2('Weight at time of sale', Icons.monitor_weight_rounded))),
          const SizedBox(height: 12),

          _Field(label: 'Payment Method', child: Row(children: [
            Expanded(child: _PayMethodBtn(label: 'Cash', icon: Icons.payments_rounded, selected: _payMethod == 'cash', color: AppColors.success, onTap: () => setState(() { _payMethod = 'cash'; _mpesaInitiated = false; _mpesaError = null; }))),
            const SizedBox(width: 10),
            Expanded(child: _PayMethodBtn(label: 'M-PESA', icon: Icons.phone_android_rounded, selected: _payMethod == 'mpesa', color: const Color(0xFF4CAF50), onTap: () => setState(() => _payMethod = 'mpesa'))),
          ])),
          const SizedBox(height: 12),

          if (_payMethod == 'mpesa') ...[
            _Field(label: 'Customer Phone *', child: TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14), decoration: _dec2('e.g. 0712345678', Icons.phone_rounded), validator: _payMethod == 'mpesa' ? (v) { if (v == null || v.trim().isEmpty) return 'Phone required for M-PESA'; return null; } : null)),
            const SizedBox(height: 8),
            if (_mpesaInitiated && _checkoutRequestId != null) Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))), child: Column(children: [
              Row(children: [const Icon(Icons.phone_android_rounded, size: 18, color: AppColors.primary), const SizedBox(width: 8), const Expanded(child: Text('STK Push Sent to Buyer!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Poppins'))), if (_mpesaVerifying) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))]),
              const SizedBox(height: 6), const Text('Ask buyer to enter M-PESA PIN. Auto-verified.', style: TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: GestureDetector(onTap: _mpesaVerifying ? null : () => _checkPaymentStatus(auto: false), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('Check Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins'))])))),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(onTap: () => _completeSale(paymentMethod: 'M-PESA (confirmed)'), child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_rounded, size: 14, color: AppColors.success), SizedBox(width: 6), Text('Mark as Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'Poppins'))])))),
              ]),
            ])),
            if (_mpesaError != null) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))), child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger), const SizedBox(width: 8), Expanded(child: Text(_mpesaError!, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontFamily: 'Poppins')))]))],
            const SizedBox(height: 12),
          ],

          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _loading ? null : _handleSell,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            child: _loading
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text('Processing...', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600))])
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_payMethod == 'mpesa' && !_mpesaInitiated ? Icons.phone_android_rounded : Icons.sell_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(_payMethod == 'mpesa' && !_mpesaInitiated ? 'Send STK Push & Sell' : 'Confirm Sale (Cash)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            ]),
          )),
          const SizedBox(height: 8),
          const Text('Confirming will mark this pig as SOLD in your records.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
        ])))),
      ]),
    );
  }

  Future<void> _handleSell() async {
    if (!_form.currentState!.validate()) return;
    if (_payMethod == 'cash') { await _completeSale(paymentMethod: 'Cash'); }
    else { await _sendMpesaAndSell(); }
  }

  Future<void> _sendMpesaAndSell() async {
    setState(() { _loading = true; _mpesaError = null; });
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      final result = await MpesaService.stkPush(phoneNumber: _phoneCtrl.text.trim(), amount: amount, accountReference: widget.pigTagId, transactionDesc: 'Pig Sale');
      if (!mounted) return;
      if (result.success && result.checkoutRequestId != null) {
        setState(() { _checkoutRequestId = result.checkoutRequestId; _mpesaInitiated = true; _mpesaError = null; _pollCount = 0; });
        _startPolling();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('M-PESA prompt sent to buyer!', style: TextStyle(fontFamily: 'Poppins')), backgroundColor: Color(0xFF4CAF50), behavior: SnackBarBehavior.floating));
      } else {
        setState(() => _mpesaError = result.errorMessage ?? 'STK push failed.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_pollCount >= 6) { _pollTimer?.cancel(); if (mounted) setState(() { _mpesaVerifying = false; _mpesaError = 'Timeout. Tap "Mark as Paid" if buyer paid.'; }); return; }
      _pollCount++;
      await _checkPaymentStatus(auto: true);
    });
  }

  Future<void> _checkPaymentStatus({bool auto = false}) async {
    if (_checkoutRequestId == null) return;
    if (mounted) setState(() => _mpesaVerifying = true);
    try {
      final result = await MpesaService.queryStatus(checkoutRequestId: _checkoutRequestId!);
      if (!mounted) return;
      if (result.paid) { _pollTimer?.cancel(); setState(() => _mpesaVerifying = false); await _completeSale(paymentMethod: 'M-PESA'); }
      else if (!result.pending) { _pollTimer?.cancel(); setState(() { _mpesaVerifying = false; _mpesaError = result.resultDesc ?? 'Payment not completed.'; _mpesaInitiated = false; }); }
      else { if (!auto) setState(() => _mpesaVerifying = false); }
    } catch (_) { if (mounted) setState(() => _mpesaVerifying = false); }
  }

  Future<void> _completeSale({required String paymentMethod}) async {
    setState(() => _loading = true);
    _pollTimer?.cancel();
    try {
      final auth   = context.read<AuthProvider>();
      final uid    = auth.uid;
      if (uid == null) throw Exception('Not signed in');

      final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
      final buyer  = _buyerCtrl.text.trim();

      final tx = TransactionModel(
        id: '', userId: uid, type: TransactionType.sale, category: 'Pig Sale',
        description: 'Sold ${widget.pigName} (${widget.pigTagId}) to $buyer',
        amount: amount, date: DateTime.now(), createdAt: DateTime.now(),
        pigId: widget.pigId, pigName: widget.pigName, receiptUrl: paymentMethod,
      );

      // ✅ Save via provider
      final ok = await context.read<FinanceProvider>().addTransaction(tx);
      if (!mounted) return;

      if (ok) {
        await context.read<PigProvider>().updatePigStatus(widget.pigId, PigStatus.sold);
        // ✅ Force finance refresh
        context.read<FinanceProvider>().forceInit(uid);
        Navigator.pop(context);
        widget.onSold();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.sell_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text('${widget.pigName} sold to $buyer for KSh ${amount.toStringAsFixed(0)} via $paymentMethod!', style: const TextStyle(fontFamily: 'Poppins')))]),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 4),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static InputDecoration _dec2(String hint, IconData icon) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins'),
    prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
    filled: true, fillColor: AppColors.offWhite,
    border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
    focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}