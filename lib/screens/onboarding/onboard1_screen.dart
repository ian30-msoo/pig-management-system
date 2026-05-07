// lib/screens/onboarding/onboard1_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/common/widgets.dart';
import 'onboard2_screen.dart';

class Onboard1Screen extends StatefulWidget {
  const Onboard1Screen({super.key});
  @override
  State<Onboard1Screen> createState() => _Onboard1ScreenState();
}

class _Onboard1ScreenState extends State<Onboard1Screen> {
  String? _selectedRole;
  String? _selectedCounty;
  bool    _loading = false;

  // ✅ IMPORTANT: These IDs must exactly match what main_scaffold.dart checks.
  // main_scaffold.dart does: (user?.role ?? '') == 'Veterinarian'
  // So role IDs here must be 'Pig Farmer' and 'Veterinarian' — exact match.
  final _roles = [
    {
      'id':    'Pig Farmer',
      'icon':  Icons.agriculture_rounded,
      'desc':  'I own or manage pigs on my farm',
      'color': AppColors.primary,
    },
    {
      'id':    'Veterinarian',
      'icon':  Icons.medical_services_rounded,
      'desc':  'I provide animal health care services',
      'color': const Color(0xFF0EA5E9),
    },
  ];

  // ── Searchable county selector ─────────────────────────────────────────────

  Future<void> _pickCounty() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountyPickerSheet(),
    );
    if (result != null) setState(() => _selectedCounty = result);
  }

  Future<void> _continue() async {
    if (_selectedRole == null || _selectedCounty == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.info_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Please select your role and county',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        ]),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<app_auth.AuthProvider>();

    // ✅ Save role and county to Firestore via updateProfile.
    // The key 'role' must match what UserModel reads from Firestore.
    final success = await auth.updateProfile({
      'role':   _selectedRole,   // e.g. "Pig Farmer" or "Veterinarian"
      'county': _selectedCounty, // e.g. "Nairobi"
    });

    if (!mounted) return;

    if (!success) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.error_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Failed to save profile. Please try again.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    // ✅ DEBUG: confirm what was saved (remove in production)
    debugPrint('✅ Onboard1 — role saved: ${auth.user?.role} | county: ${auth.user?.displayCounty}');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Onboard2Screen()),
    );

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: mq.padding.top + 16,
            left: 22,
            right: 22,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _StepDot(active: true, label: '1'),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _StepDot(active: false, label: '2'),
            ]),
            const SizedBox(height: 16),
            const Text('Tell us about yourself',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Text('Step 1 of 2 — Choose your role & county',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontFamily: 'Poppins')),
          ]),
        ),

        // ── Body ───────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding:
            EdgeInsets.fromLTRB(20, 20, 20, mq.padding.bottom + 24),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Role selection
              const Text('I am a...',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray600,
                      letterSpacing: 0.5,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 12),

              ..._roles.map((r) {
                final selected = _selectedRole == r['id'];
                final color = r['color'] as Color;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedRole = r['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.12)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(r['icon'] as IconData,
                            size: 26,
                            color: selected ? color : AppColors.gray400),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['id'] as String,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: selected ? color : AppColors.dark,
                                      fontFamily: 'Poppins')),
                              const SizedBox(height: 3),
                              Text(r['desc'] as String,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray400,
                                      fontFamily: 'Poppins',
                                      height: 1.3)),
                            ]),
                      ),
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? color : const Color(0xFFE5E7EB),
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                            : null,
                      ),
                    ]),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // County selection
              const Text('Your County',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray600,
                      letterSpacing: 0.5,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              const Text(
                  'This determines which local farmer group you join for county-specific discussions.',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                      fontFamily: 'Poppins',
                      height: 1.4)),
              const SizedBox(height: 10),

              // ✅ Searchable county selector (tappable field)
              GestureDetector(
                onTap: _pickCounty,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedCounty != null
                          ? AppColors.primary
                          : const Color(0xFFE5E7EB),
                      width: _selectedCounty != null ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8)
                    ],
                  ),
                  child: Row(children: [
                    Icon(Icons.location_on_rounded,
                        color: _selectedCounty != null
                            ? AppColors.primary
                            : AppColors.gray400,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedCounty != null) ...[
                              const Text('Selected County',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(_selectedCounty!,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dark,
                                      fontFamily: 'Poppins')),
                            ] else
                              const Text('Tap to select your county...',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.gray400,
                                      fontFamily: 'Poppins')),
                          ]),
                    ),
                    Icon(
                      _selectedCounty != null
                          ? Icons.check_circle_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: _selectedCounty != null
                          ? AppColors.success
                          : AppColors.gray400,
                      size: 22,
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                loading: _loading,
                onPressed: _continue,
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SEARCHABLE COUNTY PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CountyPickerSheet extends StatefulWidget {
  const _CountyPickerSheet();
  @override
  State<_CountyPickerSheet> createState() => _CountyPickerSheetState();
}

class _CountyPickerSheetState extends State<_CountyPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = List.from(AppConstants.kenyanCounties);
    _searchCtrl.addListener(_onSearch);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(AppConstants.kenyanCounties)
          : AppConstants.kenyanCounties
          .where((c) => c.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      height: mq.size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Select County',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                        fontFamily: 'Poppins')),
                Text('All 47 counties in Kenya',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.gray400,
                        fontFamily: 'Poppins')),
              ]),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.gray100, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.gray600),
              ),
            ),
          ]),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6)
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              style:
              const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search county...',
                hintStyle: TextStyle(
                    color: AppColors.gray400,
                    fontFamily: 'Poppins',
                    fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.gray400, size: 20),
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
            ),
          ),
        ),

        // Result count
        Padding(
          padding: const EdgeInsets.only(left: 18, bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length} ${_filtered.length == 1 ? "county" : "counties"} found',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray400,
                  fontFamily: 'Poppins'),
            ),
          ),
        ),

        const Divider(height: 1, color: AppColors.gray100),

        // Counties list
        Expanded(
          child: _filtered.isEmpty
              ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.gray200),
                    const SizedBox(height: 12),
                    Text(
                        'No county matching "${_searchCtrl.text}"',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray400,
                            fontFamily: 'Poppins')),
                  ]))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 54,
                color: AppColors.gray100),
            itemBuilder: (_, i) {
              final county = _filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Text(_countyEmoji(county),
                          style:
                          const TextStyle(fontSize: 20))),
                ),
                title: Text(county,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: AppColors.dark)),
                subtitle: Text('$county County, Kenya',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray400,
                        fontFamily: 'Poppins')),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.gray400),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () => Navigator.pop(context, county),
              );
            },
          ),
        ),
      ]),
    );
  }

  String _countyEmoji(String county) {
    const coast = [
      'Mombasa', 'Kwale', 'Kilifi', 'Tana River', 'Lamu', 'Taita Taveta'
    ];
    const ne = ['Garissa', 'Wajir', 'Mandera', 'Marsabit', 'Isiolo'];
    const eastern = [
      'Meru', 'Tharaka-Nithi', 'Embu', 'Kitui', 'Machakos', 'Makueni'
    ];
    const central = [
      'Nyandarua', 'Nyeri', 'Kirinyaga', "Murang'a", 'Kiambu'
    ];
    const rift = [
      'Turkana', 'West Pokot', 'Samburu', 'Trans Nzoia', 'Uasin Gishu',
      'Elgeyo Marakwet', 'Nandi', 'Baringo', 'Laikipia', 'Nakuru',
      'Narok', 'Kajiado', 'Kericho', 'Bomet'
    ];
    const western = ['Kakamega', 'Vihiga', 'Bungoma', 'Busia'];
    const nyanza = [
      'Siaya', 'Kisumu', 'Homa Bay', 'Migori', 'Kisii', 'Nyamira'
    ];

    if (county == 'Nairobi') return '🏙️';
    if (coast.contains(county)) return '🌊';
    if (ne.contains(county)) return '🌵';
    if (eastern.contains(county)) return '🏔️';
    if (central.contains(county)) return '🌿';
    if (rift.contains(county)) return '🦒';
    if (western.contains(county)) return '🌾';
    if (nyanza.contains(county)) return '🐟';
    return '📍';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP DOT
// ─────────────────────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color:
      active ? Colors.white : Colors.white.withValues(alpha: 0.3),
    ),
    child: Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'Poppins',
          color: active ? AppColors.primary : Colors.white,
        ),
      ),
    ),
  );
}