import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/common/widgets.dart';
import '../onboarding/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<app_auth.AuthProvider>();
    final pigs    = context.watch<PigProvider>();
    final finance = context.watch<FinanceProvider>();
    final user    = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(slivers: [

        SliverToBoxAdapter(child: Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 20, right: 20, bottom: 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: Column(children: [
            Row(children: [
              _CircleIconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
              const Spacer(),
              _CircleIconBtn(icon: Icons.edit_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
            ]),
            const SizedBox(height: 14),
            Container(
              width: 82, height: 82,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3)),
              child: user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(21), child: Image.network(user.photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 40)))
                  : const Icon(Icons.person_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 10),
            Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'Farmer', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
            const SizedBox(height: 3),
            Text(user?.email ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14), const SizedBox(width: 5),
                Text('${user?.displayRole} · ${user?.displayCounty.isNotEmpty == true ? user!.displayCounty : "Kenya"}', style: const TextStyle(fontSize: 11, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              _StatBadge(value: '${pigs.totalPigs}', label: 'Pigs'),
              _StatBadge(value: '${pigs.feeding.length}', label: 'Feedings'),
              _StatBadge(value: 'KSh ${(finance.totalIncome / 1000).toStringAsFixed(0)}K', label: 'Revenue'),
            ]),
          ]),
        )),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            _SectionTitle('Farm Information'),
            _InfoCard([
              _infoRow(Icons.agriculture_rounded, 'Farm Name', user?.farmName?.isNotEmpty == true ? user!.farmName! : 'Not set'),
              _infoRow(Icons.map_rounded, 'County', user?.county?.isNotEmpty == true ? user!.county! : 'Not set'),
              _infoRow(Icons.straighten_rounded, 'Farm Size', user?.farmSize?.isNotEmpty == true ? user!.farmSize! : 'Not set'),
              _infoRow(Icons.phone_rounded, 'Phone', user?.phone.isNotEmpty == true ? user!.phone : 'Not set'),
              _infoRow(Icons.people_alt_rounded, 'Role', user?.displayRole ?? 'Pig Farmer'),
            ]),
            const SizedBox(height: 16),

            _SectionTitle('Communities'),
            (user?.communities.isEmpty != false)
                ? _EmptyCard(icon: Icons.people_rounded, text: 'No communities joined yet')
                : _InfoCard(user!.communities.map((c) => _infoRow(Icons.group_rounded, c, 'Member')).toList()),
            const SizedBox(height: 16),

            _SectionTitle('Account Settings'),
            _InfoCard([
              _actionRow(Icons.lock_rounded, 'Change Password', () => _changePasswordDialog(context)),
              _actionRow(Icons.notifications_rounded, 'Notifications', () {}),
              _actionRow(Icons.privacy_tip_rounded, 'Privacy & Security', () {}),
              _actionRow(Icons.help_rounded, 'Help & Support', () {}),
            ]),
            const SizedBox(height: 20),

            // ✅ Sign out button
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _signOutDialog(context),
                icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                label: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        )),
      ]),
    );
  }

  void _changePasswordDialog(BuildContext context) {
    final currCtrl = TextEditingController();
    final newCtrl  = TextEditingController();
    final formKey  = GlobalKey<FormState>();
    bool showCurr  = false;
    bool showNew   = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Change Password', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        AppTextField(label: 'Current Password', controller: currCtrl, obscure: !showCurr,
            suffixIcon: IconButton(icon: Icon(showCurr ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.gray400), onPressed: () => setS(() => showCurr = !showCurr)),
            validator: (v) => v!.isEmpty ? 'Current password is required' : null),
        const SizedBox(height: 12),
        AppTextField(label: 'New Password', controller: newCtrl, obscure: !showNew,
            suffixIcon: IconButton(icon: Icon(showNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.gray400), onPressed: () => setS(() => showNew = !showNew)),
            validator: AppValidators.password),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx);
            final auth = context.read<app_auth.AuthProvider>();
            final ok   = await auth.updatePassword(currCtrl.text, newCtrl.text);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? 'Password updated successfully!' : (auth.error ?? 'Failed to update password')),
              backgroundColor: ok ? AppColors.success : AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
            if (!ok) auth.clearError();
          },
          child: const Text('Update', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ],
    )));
  }

  void _signOutDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Sign Out', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
      content: const Text('Are you sure you want to sign out?', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins'))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            Navigator.pop(ctx); // close dialog
            // ✅ Pass context so all providers get reset before sign out
            await context.read<app_auth.AuthProvider>().signOut(context: context);
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (_) => false,
              );
            }
          },
          child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ],
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  EDIT PROFILE SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstCtrl, _lastCtrl, _phoneCtrl, _farmCtrl, _sizeCtrl, _bioCtrl;
  String? _county, _role;
  bool _saving = false;

  static const List<String> _roles = ['Pig Farmer', 'Veterinarian', 'Agricultural Officer', 'Researcher', 'Trader'];

  @override
  void initState() {
    super.initState();
    final user = context.read<app_auth.AuthProvider>().user;

    String phoneDigits = user?.phone ?? '';
    if (phoneDigits.startsWith('+254')) phoneDigits = phoneDigits.substring(4);

    _firstCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastCtrl  = TextEditingController(text: user?.lastName  ?? '');
    _phoneCtrl = TextEditingController(text: phoneDigits);
    _farmCtrl  = TextEditingController(text: user?.farmName  ?? '');
    _sizeCtrl  = TextEditingController(text: user?.farmSize  ?? '');
    _bioCtrl   = TextEditingController(text: user?.bio       ?? '');
    _county    = user?.county?.isNotEmpty == true ? user?.county : null;

    final stored = user?.role ?? '';
    if (_roles.contains(stored))  { _role = stored; }
    else if (stored == 'Farmer')  { _role = 'Pig Farmer'; }
    else                          { _role = 'Pig Farmer'; }
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose(); _phoneCtrl.dispose();
    _farmCtrl.dispose();  _sizeCtrl.dispose(); _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<app_auth.AuthProvider>();
    final ok = await auth.updateProfile({
      'firstName': _firstCtrl.text.trim(),
      'lastName':  _lastCtrl.text.trim(),
      'phone':     '+254${_phoneCtrl.text.trim()}',
      'farmName':  _farmCtrl.text.trim(),
      'farmSize':  _sizeCtrl.text.trim(),
      'bio':       _bioCtrl.text.trim(),
      'county':    _county ?? '',
      'role':      _role   ?? 'Pig Farmer',
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Failed to update. Please try again.'),
        backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating,
      ));
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins', fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [

          _SectionTitle('Personal Information'),
          AppCard(padding: const EdgeInsets.all(16), child: Column(children: [
            Row(children: [
              Expanded(child: AppTextField(label: 'First Name', controller: _firstCtrl, capitalization: TextCapitalization.words, prefixIcon: const Icon(Icons.person_rounded, size: 18, color: AppColors.gray400), validator: (v) => v!.trim().isEmpty ? 'First name is required' : null)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(label: 'Last Name', controller: _lastCtrl, capitalization: TextCapitalization.words, prefixIcon: const Icon(Icons.person_rounded, size: 18, color: AppColors.gray400), validator: (v) => v!.trim().isEmpty ? 'Last name is required' : null)),
            ]),
            // Phone field
            Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneCtrl, keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.dark),
                decoration: InputDecoration(
                  hintText: '7XX XXX XXX', hintStyle: const TextStyle(color: AppColors.gray400, fontFamily: 'Poppins', fontSize: 14),
                  prefixIcon: Container(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🇰🇪', style: TextStyle(fontSize: 18)), const SizedBox(width: 6),
                    const Text('+254', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins', fontSize: 14)), const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: AppColors.gray400.withValues(alpha: 0.4)),
                  ])),
                  filled: true, fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  if (v.trim().length < 9) return 'Enter 9 digits after +254';
                  return null;
                },
              ),
            ])),
            AppTextField(label: 'Bio (optional)', hint: 'Tell others about yourself...', controller: _bioCtrl, capitalization: TextCapitalization.sentences, maxLines: 3),
          ])),

          const SizedBox(height: 16),
          _SectionTitle('Farm Details'),
          AppCard(padding: const EdgeInsets.all(16), child: Column(children: [
            AppTextField(label: 'Farm Name', hint: 'e.g. Wanjohi Farm', controller: _farmCtrl, capitalization: TextCapitalization.words, prefixIcon: const Icon(Icons.agriculture_rounded, size: 18, color: AppColors.gray400)),
            AppTextField(label: 'Farm Size', hint: 'e.g. 2 Acres', controller: _sizeCtrl, prefixIcon: const Icon(Icons.straighten_rounded, size: 18, color: AppColors.gray400)),
            _DropdownField(label: 'County', value: _county, items: AppConstants.kenyanCounties, onChanged: (v) => setState(() => _county = v)),
            _DropdownField(label: 'Role', value: _role, items: _roles, onChanged: (v) => setState(() => _role = v)),
          ])),

          const SizedBox(height: 24),
          PrimaryButton(label: 'Save Changes', icon: Icons.save_rounded, onPressed: _save, loading: _saving),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white, size: 18)));
}

class _StatBadge extends StatelessWidget {
  final String value, label;
  const _StatBadge({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15, fontFamily: 'Poppins')),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'Poppins')),
    ]),
  ));
}

class _SectionTitle extends StatelessWidget {
  final String title; const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 2), child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 1, fontFamily: 'Poppins')));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> rows; const _InfoCard(this.rows);
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
    child: Column(children: List.generate(rows.length, (i) => Column(children: [rows[i], if (i < rows.length - 1) const Divider(height: 1, indent: 52, endIndent: 16)]))),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon; final String text;
  const _EmptyCard({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
    child: Row(children: [Icon(icon, color: AppColors.gray400, size: 20), const SizedBox(width: 10), Text(text, style: const TextStyle(color: AppColors.gray400, fontFamily: 'Poppins', fontSize: 13))]),
  );
}

Widget _infoRow(IconData icon, String label, String value) => ListTile(
  leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.gray600, size: 18)),
  title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.dark, fontFamily: 'Poppins')),
  trailing: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.gray400, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
  dense: true,
);

Widget _actionRow(IconData icon, String label, VoidCallback onTap) => ListTile(
  onTap: onTap,
  leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.gray600, size: 18)),
  title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.dark, fontFamily: 'Poppins')),
  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400, size: 20),
  dense: true,
);

class _DropdownField extends StatelessWidget {
  final String label; final String? value; final List<String> items; final void Function(String?) onChanged;
  const _DropdownField({required this.label, this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        value: value, onChanged: onChanged, isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          filled: true, fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        items: items.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14, fontFamily: 'Poppins')))).toList(),
        hint: Text('Select $label', style: const TextStyle(fontFamily: 'Poppins', color: AppColors.gray400, fontSize: 14)),
      ),
    ]),
  );
}