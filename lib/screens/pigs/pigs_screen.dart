// lib/screens/pigs/pigs_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../models/pig_model.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/common/widgets.dart';
import '../finance/finance_screen.dart';
import '../camera/in_app_camera_screen.dart';   // ✅ NEW: in-app camera

// ignore_for_file: lines_longer_than_80_chars

const List<String> _suggestedNames = [
  'Simba','Tembo','Imara','Jasiri','Hodari','Furaha','Amani','Kiburi','Shujaa','Nguvu',
  'Karibu','Baraka','Neema','Zawadi','Mara','Kilima','Savanna','Nairobi','Kisumu','Nakuru',
  'Bacon','Hamlet','Wilbur','Peppa','Babe','Porky','Truffle','Hazel','Oink','Snout',
  'Duma','Tamu','Pumzi','Safi','Ziwa','Mlima','Bonde','Shamba','Eldoret','Malindi',
];

// ─────────────────────────────────────────────────────────────────────────────
//  PIGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PigsScreen extends StatefulWidget {
  const PigsScreen({super.key});
  @override
  State<PigsScreen> createState() => _PigsScreenState();
}

class _PigsScreenState extends State<PigsScreen> {
  String _filter = 'Available';

  List<PigModel> _applyFilter(List<PigModel> all) {
    switch (_filter) {
      case 'Available':  return all.where((p) => p.isActive).toList();
      case 'Healthy':    return all.where((p) => p.status == PigStatus.healthy).toList();
      case 'Sick':       return all.where((p) => p.status == PigStatus.sick).toList();
      case 'Quarantine': return all.where((p) => p.status == PigStatus.quarantine).toList();
      case 'Sold':       return all.where((p) => p.status == PigStatus.sold).toList();
      default:           return all.where((p) => p.isActive).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pigs     = context.watch<PigProvider>();
    final allPigs  = pigs.allPigs;
    final filtered = _applyFilter(allPigs);
    final soldCount = pigs.soldCount;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(children: [
        Container(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20, right: 20, bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28)),
          ),
          child: Column(children: [
            Row(children: [
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34, height: 34,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('My Pigs',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                        color: Colors.white, fontFamily: 'Poppins')),
                Text('${pigs.totalPigs} available · $soldCount sold',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70,
                        fontFamily: 'Poppins')),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (_filter == 'Sold' && soldCount > 0) ...[
                  GestureDetector(
                    onTap: () => _confirmBulkDeleteSold(context, soldCount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_sweep_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Clear All',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w600, fontSize: 11,
                                    fontFamily: 'Poppins')),
                          ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () => _openAddSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5)),
                    child: const Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Add Pig',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w600, fontSize: 12,
                                  fontFamily: 'Poppins')),
                        ]),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Available', 'Healthy', 'Sick', 'Quarantine', 'Sold']
                    .map((f) {
                  int count = 0;
                  switch (f) {
                    case 'Available':  count = pigs.totalPigs; break;
                    case 'Healthy':    count = pigs.healthyCount; break;
                    case 'Sick':       count = pigs.sickCount; break;
                    case 'Quarantine': count = pigs.quarantineCount; break;
                    case 'Sold':       count = pigs.soldCount; break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                            color: _filter == f
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('$f ($count)',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: _filter == f
                                    ? AppColors.primary
                                    : Colors.white,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
        Expanded(
          child: pigs.loading
              ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
              : filtered.isEmpty
              ? _EmptyPigs(
              onAdd: () => _openAddSheet(context), filter: _filter)
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _PigCard(
              pig: filtered[i],
              onTap: () =>
                  _openDetailSheet(context, filtered[i]),
              onDelete: () =>
                  _confirmDelete(context, filtered[i]),
              onSell: filtered[i].isActive
                  ? () => _openSellSheet(context, filtered[i])
                  : null,
            ),
          ),
        ),
      ]),
    );
  }

  void _openAddSheet(BuildContext ctx) {
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AddPigSheet(
            existingCount: ctx.read<PigProvider>().allPigs.length));
  }

  void _openDetailSheet(BuildContext ctx, PigModel pig) {
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PigDetailSheet(pig: pig));
  }

  void _openSellSheet(BuildContext ctx, PigModel pig) {
    showModalBottomSheet(
        context: ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SellPigSheet(
          pigId: pig.id,
          pigName: pig.name,
          pigTagId: pig.tagId,
          currentWeight: pig.weight,
          onSold: () {},
        ));
  }

  Future<void> _confirmBulkDeleteSold(
      BuildContext ctx, int count) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete All Sold Pigs?',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        content: Text(
            'This will permanently delete all $count sold pig records. This cannot be undone.',
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray600,
                fontFamily: 'Poppins')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.gray600, fontFamily: 'Poppins'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete All',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await ctx.read<PigProvider>().deleteAllSold();
      if (ctx.mounted) setState(() => _filter = 'Available');
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, PigModel pig) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Remove ${pig.name}?',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        content: Text("This will permanently delete ${pig.name}'s record.",
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
                fontFamily: 'Poppins')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.gray600, fontFamily: 'Poppins'))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
              TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins'))),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await ctx.read<PigProvider>().deletePig(pig.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('${pig.name} removed',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyPigs extends StatelessWidget {
  final VoidCallback onAdd;
  final String filter;
  const _EmptyPigs({required this.onAdd, required this.filter});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(28)),
          child: const Center(
              child: Icon(Icons.pets_rounded,
                  size: 42, color: AppColors.primary))),
      const SizedBox(height: 18),
      Text(
          filter == 'Available' || filter == 'Healthy'
              ? 'No Pigs Found'
              : 'No $filter Pigs',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.dark, fontFamily: 'Poppins')),
      const SizedBox(height: 6),
      Text(
          filter == 'Available'
              ? 'Register your first pig to start tracking'
              : 'No pigs with $filter status',
          style: const TextStyle(
              fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins')),
      if (filter == 'Available') ...[
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Add First Pig',
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 14,
                      fontFamily: 'Poppins')),
            ]),
          ),
        ),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PIG CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PigCard extends StatelessWidget {
  final PigModel pig;
  final VoidCallback onTap, onDelete;
  final VoidCallback? onSell;
  const _PigCard({required this.pig, required this.onTap, required this.onDelete, this.onSell});

  @override
  Widget build(BuildContext context) {
    final isSold = pig.status == PigStatus.sold;
    return GestureDetector(
      onTap: isSold ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSold ? AppColors.offWhite : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSold ? Border.all(color: AppColors.gray200) : null,
          boxShadow: isSold ? [] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14, offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _PigAvatar(pig: pig, size: 62),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(pig.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: isSold ? AppColors.gray400 : AppColors.dark,
                          fontFamily: 'Poppins'))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: pig.status.bgColor,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(pig.status.label,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: pig.status.color, fontFamily: 'Poppins')),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Text(pig.tagId,
                      style: const TextStyle(fontSize: 11, color: AppColors.primary,
                          fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                  const Text(' · ', style: TextStyle(color: AppColors.gray400, fontSize: 11)),
                  Expanded(child: Text(pig.breed, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins'))),
                ]),
                if (pig.location != null && pig.location!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 11, color: AppColors.gray400),
                    const SizedBox(width: 2),
                    Text(pig.location!,
                        style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins'))
                  ]),
                ],
                const SizedBox(height: 6),
                Wrap(spacing: 8, children: [
                  _InfoChip(icon: Icons.monitor_weight_rounded, label: '${pig.weight.toStringAsFixed(0)} kg'),
                  _InfoChip(icon: pig.gender == PigGender.male ? Icons.male_rounded : Icons.female_rounded, label: pig.gender == PigGender.male ? 'Male' : 'Female'),
                  _InfoChip(icon: Icons.cake_rounded, label: pig.ageLabel),
                ]),
              ])),
              GestureDetector(
                  onTap: onDelete,
                  child: const Padding(padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.gray400))),
            ]),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            decoration: BoxDecoration(
              color: isSold ? const Color(0xFFF0F0F0) : AppColors.offWhite,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(20)),
                child: Text(pig.stage, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.blue, fontFamily: 'Poppins')),
              ),
              const Spacer(),
              if (!isSold && onSell != null)
                GestureDetector(
                  onTap: onSell,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.sell_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Sell', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                    ]),
                  ),
                )
              else if (isSold)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppColors.gray400),
                    SizedBox(width: 4),
                    Text('Sold — No Longer Active',
                        style: TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                  ]),
                )
              else ...[
                  const Text('Tap for details', style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.gray400),
                ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PIG AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class _PigAvatar extends StatelessWidget {
  final PigModel pig;
  final double   size;
  const _PigAvatar({required this.pig, this.size = 58});

  bool get _hasImage {
    final url = pig.imageUrl?.trim() ?? '';
    return url.isNotEmpty && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    if (_hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          pig.imageUrl!.trim(),
          width: size, height: size,
          fit: BoxFit.cover,
          // Show placeholder while loading
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
            width: size, height: size,
            decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(16)),
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          // Fall back to emoji placeholder on error
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16)),
    child: Center(
      child: Text(pig.stageEmoji, style: TextStyle(fontSize: size * 0.48)),
    ),
  );
}
class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppColors.gray400),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'Poppins')),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD PIG SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddPigSheet extends StatefulWidget {
  final int existingCount;
  const _AddPigSheet({this.existingCount = 0});
  @override
  State<_AddPigSheet> createState() => _AddPigSheetState();
}

class _AddPigSheetState extends State<_AddPigSheet> {
  final _form         = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _tagCtrl      = TextEditingController();
  final _weightCtrl   = TextEditingController();
  final _notesCtrl    = TextEditingController();
  final _locationCtrl = TextEditingController();

  String   _breed    = AppConstants.pigBreeds.first;
  String   _stage    = AppConstants.pigStages.first;
  String   _gender   = 'male';
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 60));
  bool     _loading  = false;
  bool     _uploadingImage = false;
  File?    _imageFile;

  @override
  void initState() {
    super.initState();
    _tagCtrl.text = 'P${(widget.existingCount + 1).toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _tagCtrl.dispose(); _weightCtrl.dispose();
    _notesCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  // ✅ NEW: Opens the in-app camera (WhatsApp-style) then falls back to gallery
  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Add Pig Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins', color: AppColors.dark)),
          const SizedBox(height: 18),
          // ✅ In-app camera option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: AppColors.primaryBg, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 22)),
            title: const Text('Take a photo',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Opens camera inside the app',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.gray400)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray300),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          const Divider(height: 1),
          // Gallery option
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: AppColors.blueBg, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.blue, size: 22)),
            title: const Text('Choose from gallery',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Pick an existing photo',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.gray400)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray300),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ]),
      ),
    );

    if (choice == null || !mounted) return;

    File? picked;

    if (choice == 'camera') {
      // ✅ Navigate to the in-app camera — no native crash
      picked = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const InAppCamera(),
        ),
      );
    } else {
      // Gallery — uses image_picker but gallery is stable (no crash)
      final xfile = await ImagePicker().pickImage(
          source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
      if (xfile != null) picked = File(xfile.path);
    }

    if (picked != null && mounted) {
      setState(() => _imageFile = picked);
    }
  }

  /// Upload using user-scoped path so Storage rules match.
  Future<String?> _uploadImageForPig(String pigId, String uid) async {
    if (_imageFile == null) return null;
    final imageFile = _imageFile!;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('pig_photos')
          .child('$pigId.jpg');
      debugPrint('📸 Uploading pig image to: ${ref.fullPath}');
      final task = await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      final url  = await task.ref.getDownloadURL();
      debugPrint('✅ Image uploaded: $url');
      return url;
    } on FirebaseException catch (e) {
      debugPrint('❌ Storage error [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add New Pig', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
              Text('Fill in details to register', style: TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Poppins')),
            ]),
            const Spacer(),
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18))),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: Column(children: [

                // ── Photo picker ──────────────────────────────────────────
                _SectionCard(
                    title: 'Pig Photo (Optional)',
                    icon: Icons.photo_camera_rounded,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity, height: 150,
                          decoration: BoxDecoration(
                              color: AppColors.primaryBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2)),
                          child: _imageFile != null
                              ? Stack(children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_imageFile!, fit: BoxFit.cover,
                                    width: double.infinity, height: 150)),
                            Positioned(top: 8, right: 8,
                                child: GestureDetector(
                                    onTap: () => setState(() => _imageFile = null),
                                    child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white)))),
                            // ✅ Tap to change label
                            Positioned(bottom: 8, left: 0, right: 0,
                                child: Center(child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text('Tap to change', style: TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'Poppins')),
                                  ]),
                                ))),
                          ])
                              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: 24)),
                            const SizedBox(height: 8),
                            const Text('Tap to add pig photo',
                                style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                            const Text('Camera or gallery',
                                style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')),
                          ]),
                        ),
                      ),
                    ]),
                const SizedBox(height: 14),

                // ── Name ─────────────────────────────────────────────────
                _SectionCard(
                    title: 'Pig Name',
                    icon: Icons.label_rounded,
                    children: [
                      SizedBox(
                        height: 34,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _suggestedNames.length,
                          itemBuilder: (_, idx) {
                            final name = _suggestedNames[idx];
                            final sel  = _nameCtrl.text == name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _nameCtrl.text = name),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                      color: sel ? AppColors.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: sel ? AppColors.primary : AppColors.gray200)),
                                  child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: sel ? Colors.white : AppColors.dark)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                          label: 'Pig Name *',
                          hint: 'Type or tap a suggestion above',
                          controller: _nameCtrl,
                          prefixIcon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.gray400),
                          validator: (v) => AppValidators.required(v, 'Name'),
                          capitalization: TextCapitalization.words),
                    ]),
                const SizedBox(height: 14),

                _SectionCard(
                    title: 'Basic Information',
                    icon: Icons.info_outline_rounded,
                    children: [
                      AppTextField(
                          label: 'Tag / Ear Tag ID',
                          hint: 'Auto-assigned (e.g. P001)',
                          controller: _tagCtrl,
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18, color: AppColors.primary),
                          validator: (v) => AppValidators.required(v, 'Tag ID')),
                      AppTextField(
                          label: 'Weight (kg) *',
                          hint: 'e.g. 12',
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(Icons.monitor_weight_rounded, size: 18, color: AppColors.gray400),
                          validator: (v) => AppValidators.positiveNumber(v, 'Weight')),
                      AppTextField(
                          label: 'Location / Pen (optional)',
                          hint: 'e.g. Pen A, Shed 2',
                          controller: _locationCtrl,
                          prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.gray400)),
                    ]),
                const SizedBox(height: 14),

                _SectionCard(
                    title: 'Gender',
                    icon: Icons.wc_rounded,
                    children: [
                      Row(children: ['male', 'female'].map((g) {
                        final active = _gender == g;
                        return Expanded(child: Padding(
                          padding: EdgeInsets.only(right: g == 'male' ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setState(() => _gender = g),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                  color: active ? AppColors.primaryBg : AppColors.gray100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: active ? AppColors.primary : AppColors.gray200, width: 2)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(g == 'male' ? Icons.male_rounded : Icons.female_rounded,
                                    size: 20, color: active ? AppColors.primary : AppColors.gray400),
                                const SizedBox(width: 6),
                                Text(g == 'male' ? 'Male' : 'Female',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                        color: active ? AppColors.primary : AppColors.gray600, fontFamily: 'Poppins')),
                              ]),
                            ),
                          ),
                        ));
                      }).toList()),
                    ]),
                const SizedBox(height: 14),

                _SectionCard(
                    title: 'Breed & Stage',
                    icon: Icons.category_rounded,
                    children: [
                      _SheetDropdown<String>(
                          label: 'Breed', icon: Icons.category_rounded,
                          value: _breed, items: AppConstants.pigBreeds,
                          onChanged: (v) => setState(() => _breed = v!)),
                      const SizedBox(height: 14),
                      _SheetDropdown<String>(
                          label: 'Stage', icon: Icons.timeline_rounded,
                          value: _stage, items: AppConstants.pigStages,
                          onChanged: (v) => setState(() => _stage = v!)),
                    ]),
                const SizedBox(height: 14),

                _SectionCard(
                    title: 'Date of Birth',
                    icon: Icons.calendar_month_rounded,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                              context: context, initialDate: _birthDate,
                              firstDate: DateTime(2018), lastDate: DateTime.now(),
                              builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                                  child: child!));
                          if (d != null) setState(() => _birthDate = d);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray200, width: 1.5)),
                          child: Row(children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.gray400),
                            const SizedBox(width: 10),
                            Text('${_birthDate.day}/${_birthDate.month}/${_birthDate.year}',
                                style: const TextStyle(fontSize: 14, fontFamily: 'Poppins', color: AppColors.dark)),
                            const Spacer(),
                            const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                          ]),
                        ),
                      ),
                    ]),
                const SizedBox(height: 14),

                _SectionCard(
                    title: 'Notes (Optional)',
                    icon: Icons.notes_rounded,
                    children: [
                      AppTextField(label: '', hint: 'Any additional info about this pig...', controller: _notesCtrl, maxLines: 3),
                    ]),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0),
                    child: _loading || _uploadingImage
                        ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                      const SizedBox(width: 10),
                      Text(_uploadingImage ? 'Uploading photo...' : 'Saving...',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ])
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Save Pig', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter or select a pig name', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _loading = true);

    final uid         = context.read<app_auth.AuthProvider>().uid!;
    final pigProvider = context.read<PigProvider>();
    final nameText    = _nameCtrl.text.trim();
    final tagText     = _tagCtrl.text.trim().toUpperCase();
    final hasImage    = _imageFile != null;

    final pig = PigModel(
      id: '', userId: uid, name: nameText, tagId: tagText,
      breed: _breed, gender: _gender == 'male' ? PigGender.male : PigGender.female,
      birthDate: _birthDate, weight: double.tryParse(_weightCtrl.text.trim()) ?? 0,
      stage: _stage, status: PigStatus.healthy,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );

    final pigId = await pigProvider.addPig(pig);

    if (!mounted) return;
    setState(() => _loading = false);

    if (pigId == null || pigId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [
          Icon(Icons.error_rounded, color: Colors.white, size: 18), SizedBox(width: 8),
          Expanded(child: Text('Failed to save pig. Check your connection.', style: TextStyle(fontFamily: 'Poppins'))),
        ]),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ));
      return;
    }

    // Close sheet first, then upload image in background
    Navigator.pop(context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('$nameText added successfully!', style: const TextStyle(fontFamily: 'Poppins'))),
        ]),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        duration: const Duration(seconds: 3),
      ));
    }

    if (hasImage) {
      _uploadAndAttachImage(pigId: pigId, uid: uid, provider: pigProvider);
    }
  }

  Future<void> _uploadAndAttachImage({
    required String pigId, required String uid, required PigProvider provider,
  }) async {
    if (!mounted) setState(() => _uploadingImage = true);
    final url = await _uploadImageForPig(pigId, uid);
    if (url != null && url.isNotEmpty) {
      await provider.updatePigFields(pigId, {'imageUrl': url});
      debugPrint('✅ Image attached to pig $pigId');
    }
    if (mounted) setState(() => _uploadingImage = false);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INPUT DEC HELPER
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.gray600),
  prefixIcon: Icon(icon, size: 18, color: AppColors.gray400),
  filled: true, fillColor: AppColors.offWhite,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
);

// ─────────────────────────────────────────────────────────────────────────────
//  PIG DETAIL SHEET  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _PigDetailSheet extends StatefulWidget {
  final PigModel pig;
  const _PigDetailSheet({required this.pig});
  @override
  State<_PigDetailSheet> createState() => _PigDetailSheetState();
}

class _PigDetailSheetState extends State<_PigDetailSheet> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<HealthRecord> _health  = [];
  List<FeedRecord>   _feeding = [];
  List<WeightRecord> _growth  = [];
  bool _loadingRecords = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadAllRecords();
  }

  Future<void> _loadAllRecords() async {
    final provider = context.read<PigProvider>();
    final results  = await Future.wait([
      provider.getPigHealth(widget.pig.id),
      provider.getPigFeeding(widget.pig.id),
      provider.getPigWeightHistory(widget.pig.id),
    ]);
    if (mounted) {
      setState(() {
        _health  = results[0] as List<HealthRecord>;
        _feeding = results[1] as List<FeedRecord>;
        _growth  = results[2] as List<WeightRecord>;
        _loadingRecords = false;
      });
    }
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pig = widget.pig;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            Row(children: [
              _PigAvatar(pig: pig, size: 56),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pig.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                Text('${pig.tagId} · ${pig.breed}', style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Poppins')),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(pig.status.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins'))),
              const SizedBox(width: 10),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22)),
            ]),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabs, isScrollable: true,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.primary, unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [Tab(text: '  Overview  '), Tab(text: '  Health  '), Tab(text: '  Feeding  '), Tab(text: '  Growth  ')],
            ),
          ]),
        ),
        Expanded(
          child: _loadingRecords
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(controller: _tabs, children: [
            _OverviewTab(pig: pig, health: _health, feeding: _feeding, growth: _growth),
            _HealthTab(pig: pig, records: _health, onAdd: () => _openAddHealthDialog(context, pig),
                onDelete: (r) async { await context.read<PigProvider>().deleteHealthRecord(pig.id, r.id); _loadAllRecords(); }),
            _FeedingTab(pig: pig, records: _feeding, onAdd: () => _openAddFeedDialog(context, pig),
                onDelete: (r) async { await context.read<PigProvider>().deleteFeedRecord(pig.id, r.id); _loadAllRecords(); }),
            _GrowthTab(pig: pig, records: _growth, onAdd: () => _openAddWeightDialog(context, pig),
                onDelete: (r) async { await context.read<PigProvider>().deleteWeightRecord(pig.id, r.id); _loadAllRecords(); }),
          ]),
        ),
      ]),
    );
  }

  void _openAddHealthDialog(BuildContext ctx, PigModel pig) {
    String type = 'Vaccination';
    final condCtrl = TextEditingController(), treatCtrl = TextEditingController(), vetCtrl = TextEditingController(), tempCtrl = TextEditingController(), notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>(); bool saving = false;
    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Add Health Record — ${pig.name}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
      content: SizedBox(width: double.maxFinite, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: type, decoration: _inputDec('Record Type', Icons.medical_services_rounded),
            items: ['Vaccination','Treatment','Checkup','Deworming'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => type = v!)),
        const SizedBox(height: 12),
        TextFormField(controller: condCtrl, decoration: _inputDec('Condition / Diagnosis *', Icons.sick_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: treatCtrl, decoration: _inputDec('Treatment / Vaccine', Icons.vaccines_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        const SizedBox(height: 12),
        TextFormField(controller: vetCtrl, decoration: _inputDec('Vet Name', Icons.person_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        const SizedBox(height: 12),
        TextFormField(controller: tempCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDec('Temperature (°C)', Icons.thermostat_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        const SizedBox(height: 12),
        TextFormField(controller: notesCtrl, maxLines: 2, decoration: _inputDec('Notes', Icons.notes_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.gray600))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: saving ? null : () async {
            if (!formKey.currentState!.validate()) return;
            setS(() => saving = true);
            await context.read<PigProvider>().addHealthRecord(pig.id, HealthRecord(id: '', pigId: pig.id, pigName: pig.name, type: type, condition: condCtrl.text.trim(), treatment: treatCtrl.text.trim().isEmpty ? null : treatCtrl.text.trim(), veterinarian: vetCtrl.text.trim().isEmpty ? null : vetCtrl.text.trim(), temperature: tempCtrl.text.trim().isEmpty ? null : double.tryParse(tempCtrl.text.trim()), notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(), date: DateTime.now(), createdAt: DateTime.now()));
            if (dctx.mounted) Navigator.pop(dctx);
            _loadAllRecords();
          },
          child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ],
    )));
  }

  void _openAddFeedDialog(BuildContext ctx, PigModel pig) {
    String feedType = 'Grower';
    final qtyCtrl = TextEditingController(), brandCtrl = TextEditingController(), notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>(); bool saving = false;
    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Add Feed Record — ${pig.name}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(initialValue: feedType, decoration: _inputDec('Feed Type', Icons.eco_rounded),
            items: ['Starter','Grower','Finisher','Sow & Weaner','Custom'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)))).toList(),
            onChanged: (v) => setS(() => feedType = v!)),
        const SizedBox(height: 12),
        TextFormField(controller: qtyCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDec('Quantity (kg) *', Icons.monitor_weight_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: brandCtrl, decoration: _inputDec('Brand (optional)', Icons.label_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        const SizedBox(height: 12),
        TextFormField(controller: notesCtrl, maxLines: 2, decoration: _inputDec('Notes', Icons.notes_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.gray600))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: saving ? null : () async {
            if (!formKey.currentState!.validate()) return;
            setS(() => saving = true);
            await context.read<PigProvider>().addFeedRecord(pig.id, FeedRecord(id: '', pigId: pig.id, pigName: pig.name, feedType: feedType, quantityKg: double.tryParse(qtyCtrl.text.trim()) ?? 0, brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(), notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(), date: DateTime.now(), createdAt: DateTime.now()));
            if (dctx.mounted) Navigator.pop(dctx);
            _loadAllRecords();
          },
          child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ],
    )));
  }

  void _openAddWeightDialog(BuildContext ctx, PigModel pig) {
    final weightCtrl = TextEditingController(text: pig.weight.toStringAsFixed(1));
    final notesCtrl  = TextEditingController();
    final formKey = GlobalKey<FormState>(); bool saving = false;
    showDialog(context: ctx, builder: (dctx) => StatefulBuilder(builder: (dctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Log Weight — ${pig.name}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDec('Current Weight (kg) *', Icons.monitor_weight_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: notesCtrl, maxLines: 2, decoration: _inputDec('Notes (optional)', Icons.notes_rounded), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppColors.gray600))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: saving ? null : () async {
            if (!formKey.currentState!.validate()) return;
            setS(() => saving = true);
            await context.read<PigProvider>().addWeightRecord(pig.id, double.tryParse(weightCtrl.text.trim()) ?? pig.weight, notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim());
            if (dctx.mounted) Navigator.pop(dctx);
            _loadAllRecords();
          },
          child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Log', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ],
    )));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABS (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final PigModel pig; final List<HealthRecord> health; final List<FeedRecord> feeding; final List<WeightRecord> growth;
  const _OverviewTab({required this.pig, required this.health, required this.feeding, required this.growth});
  @override
  Widget build(BuildContext context) {
    final lastHealth  = health.isNotEmpty ? health.first : null;
    final lastFeeding = feeding.isNotEmpty ? feeding.first : null;
    final ongoingCount = health.where((h) => h.status == 'ongoing' || h.status == 'critical').length;
    final monthFeedKg = feeding.where((f) { final now = DateTime.now(); return f.date.month == now.month && f.date.year == now.year; }).fold<double>(0, (s, r) => s + r.quantityKg);
    return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (pig.imageUrl != null && pig.imageUrl!.isNotEmpty) Container(width: double.infinity, height: 200, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(pig.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.primaryBg, child: Center(child: Text(pig.stageEmoji, style: const TextStyle(fontSize: 64))))))),
      Row(children: [
        _StatCard(icon: Icons.monitor_weight_rounded, label: 'Weight', value: '${pig.weight.toStringAsFixed(1)} kg', color: AppColors.primary),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.cake_rounded, label: 'Age', value: pig.ageLabel, color: AppColors.blue),
        const SizedBox(width: 10),
        _StatCard(icon: pig.gender == PigGender.male ? Icons.male_rounded : Icons.female_rounded, label: 'Gender', value: pig.gender == PigGender.male ? 'Male' : 'Female', color: pig.gender == PigGender.male ? const Color(0xFF3B82F6) : const Color(0xFFEC4899)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: ongoingCount > 0 ? AppColors.dangerBg : AppColors.successBg, borderRadius: BorderRadius.circular(16)), child: Row(children: [
          Icon(ongoingCount > 0 ? Icons.medical_services_rounded : Icons.check_circle_rounded, size: 22, color: ongoingCount > 0 ? AppColors.danger : AppColors.success), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ongoingCount > 0 ? '$ongoingCount Active Issue${ongoingCount != 1 ? "s" : ""}' : 'Healthy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: ongoingCount > 0 ? AppColors.danger : AppColors.success)),
            Text('${health.length} health record${health.length != 1 ? "s" : ""}', style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
          ])),
        ]))),
        const SizedBox(width: 10),
        Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(16)), child: Row(children: [
          const Icon(Icons.eco_rounded, size: 22, color: AppColors.success), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${monthFeedKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success, fontFamily: 'Poppins')),
            const Text('fed this month', style: TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins')),
          ])),
        ]))),
      ]),
      const SizedBox(height: 14),
      _DetailCard(title: 'Pig Information', rows: [
        _buildInfoRow(Icons.tag_rounded, 'Tag ID', pig.tagId),
        _buildInfoRow(Icons.category_rounded, 'Breed', pig.breed),
        _buildInfoRow(Icons.timeline_rounded, 'Stage', pig.stage),
        if (pig.location != null && pig.location!.isNotEmpty) _buildInfoRow(Icons.location_on_rounded, 'Location', pig.location!),
        _buildInfoRow(Icons.calendar_month_rounded, 'Date of Birth', '${pig.birthDate.day}/${pig.birthDate.month}/${pig.birthDate.year}'),
        _StatusRow(pig),
      ]),
      if (lastHealth != null) ...[const SizedBox(height: 14), _DetailCard(title: 'Last Health Record', rows: [_buildInfoRow(Icons.medical_services_rounded, 'Type', lastHealth.type), _buildInfoRow(Icons.sick_rounded, 'Condition', lastHealth.condition), _buildInfoRow(Icons.calendar_today_rounded, 'Date', '${lastHealth.date.day}/${lastHealth.date.month}/${lastHealth.date.year}'), if (lastHealth.treatment != null) _buildInfoRow(Icons.vaccines_rounded, 'Treatment', lastHealth.treatment!)])],
      if (lastFeeding != null) ...[const SizedBox(height: 14), _DetailCard(title: 'Last Feeding', rows: [_buildInfoRow(Icons.eco_rounded, 'Feed Type', lastFeeding.feedType), _buildInfoRow(Icons.monitor_weight_rounded, 'Quantity', '${lastFeeding.quantityKg.toStringAsFixed(1)} kg'), _buildInfoRow(Icons.calendar_today_rounded, 'Date', '${lastFeeding.date.day}/${lastFeeding.date.month}/${lastFeeding.date.year}')])],
      if (growth.length >= 2) ...[const SizedBox(height: 14), _DetailCard(title: 'Weight Trend', rows: [_buildInfoRow(Icons.monitor_weight_rounded, 'Current', '${pig.weight.toStringAsFixed(1)} kg'), _buildInfoRow(Icons.trending_up_rounded, 'First Recorded', '${growth.first.weightKg.toStringAsFixed(1)} kg'), _buildInfoRow(Icons.show_chart_rounded, 'Total Gain', '${(pig.weight - growth.first.weightKg) >= 0 ? "+" : ""}${(pig.weight - growth.first.weightKg).toStringAsFixed(1)} kg')])],
      if (pig.notes != null && pig.notes!.isNotEmpty) ...[const SizedBox(height: 14), _DetailCard(title: 'Notes', rows: [Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(pig.notes!, style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.5)))])],
      const SizedBox(height: 14),
      _DetailCard(title: 'Record Info', rows: [_buildInfoRow(Icons.add_circle_outline_rounded, 'Added', '${pig.createdAt.day}/${pig.createdAt.month}/${pig.createdAt.year}'), _buildInfoRow(Icons.update_rounded, 'Last Updated', '${pig.updatedAt.day}/${pig.updatedAt.month}/${pig.updatedAt.year}')]),
    ]));
  }
}

class _StatusRow extends StatelessWidget {
  final PigModel pig; const _StatusRow(this.pig);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
    const Icon(Icons.health_and_safety_rounded, size: 15, color: AppColors.gray400), const SizedBox(width: 10),
    const Text('Status', style: TextStyle(fontSize: 13, color: AppColors.gray600, fontFamily: 'Poppins')), const Spacer(),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: pig.status.bgColor, borderRadius: BorderRadius.circular(20)), child: Text(pig.status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pig.status.color, fontFamily: 'Poppins'))),
  ]));
}

Widget _buildInfoRow(IconData icon, String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, size: 15, color: AppColors.gray400), const SizedBox(width: 10), Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontFamily: 'Poppins')), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')))]));

class _HealthTab extends StatelessWidget {
  final PigModel pig; final List<HealthRecord> records; final VoidCallback onAdd; final void Function(HealthRecord) onDelete;
  const _HealthTab({required this.pig, required this.records, required this.onAdd, required this.onDelete});
  Color _tc(String t) { switch(t) { case 'Vaccination': return AppColors.blue; case 'Treatment': return AppColors.danger; case 'Deworming': return AppColors.warning; default: return AppColors.success; } }
  Color _tb(String t) { switch(t) { case 'Vaccination': return AppColors.blueBg; case 'Treatment': return AppColors.dangerBg; case 'Deworming': return AppColors.warningBg; default: return AppColors.successBg; } }
  IconData _ti(String t) { switch(t) { case 'Vaccination': return Icons.vaccines_rounded; case 'Treatment': return Icons.medical_services_rounded; case 'Deworming': return Icons.pest_control_rounded; default: return Icons.health_and_safety_rounded; } }
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: GestureDetector(onTap: onAdd, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_rounded, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Add Health Record', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.danger, fontFamily: 'Poppins'))])))),
    Expanded(child: records.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.health_and_safety_rounded, size: 48, color: AppColors.gray200), SizedBox(height: 10), Text('No health records yet', style: TextStyle(fontSize: 14, color: AppColors.gray400, fontFamily: 'Poppins'))])) :
    ListView.separated(padding: const EdgeInsets.fromLTRB(16, 10, 16, 40), itemCount: records.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) {
      final r = records[i];
      return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: _tb(r.type), borderRadius: BorderRadius.circular(12)), child: Icon(_ti(r.type), size: 20, color: _tc(r.type))), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _tb(r.type), borderRadius: BorderRadius.circular(20)), child: Text(r.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _tc(r.type), fontFamily: 'Poppins'))), const Spacer(), Text('${r.date.day}/${r.date.month}/${r.date.year}', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins'))]),
          const SizedBox(height: 4), Text(r.condition, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
          if (r.treatment != null) Text('Treatment: ${r.treatment}', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins')),
          if (r.temperature != null) Text('Temp: ${r.temperature}°C', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins')),
          if (r.vetName != null) Text('Vet: ${r.vetName}', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontFamily: 'Poppins')),
        ])),
        GestureDetector(onTap: () => onDelete(r), child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.gray400)),
      ]));
    })),
  ]);
}

class _FeedingTab extends StatelessWidget {
  final PigModel pig; final List<FeedRecord> records; final VoidCallback onAdd; final void Function(FeedRecord) onDelete;
  const _FeedingTab({required this.pig, required this.records, required this.onAdd, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthTotal = records.where((r) => r.date.month == now.month && r.date.year == now.year).fold<double>(0, (s, r) => s + r.quantityKg);
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Row(children: [
        Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('This Month', style: TextStyle(fontSize: 11, color: AppColors.success, fontFamily: 'Poppins')), Text(monthTotal.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'Poppins')), const Text('kg total feed', style: TextStyle(fontSize: 10, color: AppColors.success, fontFamily: 'Poppins'))]))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: onAdd, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))), child: const Column(children: [Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28), SizedBox(height: 4), Text('Log Feeding', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins'))])))),
      ])),
      Expanded(child: records.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.eco_rounded, size: 48, color: AppColors.gray200), SizedBox(height: 10), Text('No feeding records yet', style: TextStyle(fontSize: 14, color: AppColors.gray400, fontFamily: 'Poppins'))])) :
      ListView.separated(padding: const EdgeInsets.fromLTRB(16, 10, 16, 40), itemCount: records.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
        final r = records[i];
        return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]), child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.eco_rounded, size: 20, color: AppColors.success)), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text(r.feedType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')), const Spacer(), Text('${r.quantityKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success, fontFamily: 'Poppins'))]),
            Row(children: [Text('${r.date.day}/${r.date.month}/${r.date.year}', style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins')), if (r.brand != null) ...[const Text(' · ', style: TextStyle(color: AppColors.gray400, fontSize: 11)), Text(r.brand!, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins'))]]),
          ])),
          GestureDetector(onTap: () => onDelete(r), child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.gray400)),
        ]));
      })),
    ]);
  }
}

class _GrowthTab extends StatelessWidget {
  final PigModel pig; final List<WeightRecord> records; final VoidCallback onAdd; final void Function(WeightRecord) onDelete;
  const _GrowthTab({required this.pig, required this.records, required this.onAdd, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final gainKg = records.length >= 2 ? records.last.weightKg - records.first.weightKg : null;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Row(children: [
        Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Current Weight', style: TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'Poppins')), Text('${pig.weight.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Poppins')), if (gainKg != null) Text('${gainKg >= 0 ? "+" : ""}${gainKg.toStringAsFixed(1)} kg gain', style: const TextStyle(fontSize: 10, color: AppColors.primary, fontFamily: 'Poppins'))]))),
        const SizedBox(width: 10),
        Expanded(child: GestureDetector(onTap: onAdd, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.blueBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.blue.withValues(alpha: 0.3))), child: const Column(children: [Icon(Icons.monitor_weight_rounded, color: AppColors.blue, size: 28), SizedBox(height: 4), Text('Log Weight', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue, fontFamily: 'Poppins'))])))),
      ])),
      Expanded(child: records.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.monitor_weight_rounded, size: 48, color: AppColors.gray200), SizedBox(height: 10), Text('No weight records yet', style: TextStyle(fontSize: 14, color: AppColors.gray400, fontFamily: 'Poppins')), SizedBox(height: 6), Text('Log weight regularly to track growth', style: TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins'))])) :
      ListView.separated(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), itemCount: records.length, separatorBuilder: (_, __) => const SizedBox(height: 8), itemBuilder: (_, i) {
        final r = records[records.length - 1 - i];
        final change = i < records.length - 1 ? records[records.length - 1 - i].weightKg - records[records.length - 2 - i].weightKg : null;
        return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]), child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.monitor_weight_rounded, size: 20, color: AppColors.primary)), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r.date.day}/${r.date.month}/${r.date.year}', style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
            if (r.notes != null) Text(r.notes!, style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontFamily: 'Poppins', fontStyle: FontStyle.italic)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${r.weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.dark, fontFamily: 'Poppins')),
            if (change != null) Text('${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)} kg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: change >= 0 ? AppColors.success : AppColors.danger, fontFamily: 'Poppins')),
          ]),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => onDelete(r), child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.gray400)),
        ]));
      })),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)), const SizedBox(height: 6), Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray400, fontFamily: 'Poppins'))])));
}

class _DetailCard extends StatelessWidget {
  final String title; final List<Widget> rows;
  const _DetailCard({required this.title, required this.rows});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')), const SizedBox(height: 12), ...rows]));
}

class _SectionCard extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 15, color: AppColors.primary), const SizedBox(width: 7), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'))]), const SizedBox(height: 14), ...children]));
}

class _SheetDropdown<T> extends StatelessWidget {
  final String label; final IconData icon; final T value; final List<T> items; final ValueChanged<T?> onChanged;
  const _SheetDropdown({required this.label, required this.icon, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'Poppins')),
    const SizedBox(height: 6),
    DropdownButtonFormField<T>(initialValue: value,
      decoration: InputDecoration(prefixIcon: Icon(icon, size: 18, color: AppColors.gray400), filled: true, fillColor: AppColors.offWhite, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
      isExpanded: true,
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(item.toString(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)))).toList(),
      onChanged: onChanged,
    ),
  ]);
}