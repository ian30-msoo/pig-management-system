// lib/screens/onboarding/onboard2_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../../widgets/common/widgets.dart';
import '../main/main_scaffold.dart';

class Onboard2Screen extends StatefulWidget {
  const Onboard2Screen({super.key});
  @override
  State<Onboard2Screen> createState() => _Onboard2ScreenState();
}

class _Onboard2ScreenState extends State<Onboard2Screen> {
  bool _joinedCounty  = false;
  bool _joinedGeneral = false;
  bool _loading       = false;

  Future<void> _finish() async {
    setState(() => _loading = true);
    final auth   = context.read<app_auth.AuthProvider>();
    final county = auth.user?.displayCounty ?? '';

    final communities = <String>[
      if (_joinedCounty && county.isNotEmpty) county,
      if (_joinedGeneral) 'General',
    ];

    await auth.updateProfile({
      'communities':        communities,
      'onboardingComplete': true,
    });
    if (!mounted) return;

    context.read<PigProvider>().init();
    context.read<FinanceProvider>().init(auth.uid ?? '');
    context.read<CommunityProvider>().init();
    context.read<ForumProvider>().init(county);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
          (_) => false,
    );
  }

  String _buildButtonLabel(String county) {
    if (_joinedCounty && _joinedGeneral && county.isNotEmpty) {
      return 'Join Selected Forums & Continue';
    } else if (_joinedCounty && county.isNotEmpty) {
      return 'Join $county Forum & Continue';
    } else if (_joinedGeneral) {
      return 'Join General Forum & Continue';
    }
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<app_auth.AuthProvider>();
    final county = auth.user?.displayCounty ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(children: [

        // ── Header ────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 22, right: 22, bottom: 24,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark]),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Step progress
            Row(children: [
              _StepDot(active: false, label: '1'),
              const SizedBox(width: 6),
              Expanded(child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 6),
              _StepDot(active: true, label: '2'),
            ]),
            const SizedBox(height: 16),
            const Text('Join a Community',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                    color: Colors.white, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Text('Step 2 of 2 — Connect with farmers near you',
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.72),
                    fontFamily: 'Poppins')),
          ]),
        ),

        // ── Body ──────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Section label
                  const Text('Available Communities',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.gray600, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  const Text(
                    'Your county forum is private — only farmers in your county see those posts. '
                        'The General Forum is visible to all pig farmers in Kenya.',
                    style: TextStyle(fontSize: 12, color: AppColors.gray400,
                        fontFamily: 'Poppins', height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // ── County community card ──────────────────────────
                  if (county.isNotEmpty) ...[
                    _CommunityCard(
                      icon: Icons.place_rounded,
                      iconColor: AppColors.primary,
                      title: '$county Pig Farmers',
                      subtitle: 'Local forum for $county county only',
                      tag: '📍 County Forum',
                      tagColor: AppColors.primary,
                      features: const [
                        'Ask questions to local farmers',
                        'Share disease alerts in your area',
                        'Find local vets & feed suppliers',
                        'Buy & sell within your county',
                      ],
                      joined: _joinedCounty,
                      onToggle: () => setState(() => _joinedCounty = !_joinedCounty),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── General / National community card ──────────────
                  _CommunityCard(
                    icon: Icons.public_rounded,
                    iconColor: AppColors.blue,
                    title: 'Kenya Pig Farmers Network',
                    subtitle: 'National forum — all counties welcome',
                    tag: '🌍 General Forum',
                    tagColor: AppColors.blue,
                    features: const [
                      'Connect with farmers across Kenya',
                      'Share breeding & feeding tips nationally',
                      'Ask vets & livestock experts',
                      'Market prices & industry news',
                    ],
                    joined: _joinedGeneral,
                    onToggle: () => setState(() => _joinedGeneral = !_joinedGeneral),
                  ),

                  const SizedBox(height: 28),

                  // ── CTA button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              (!_joinedCounty && !_joinedGeneral)
                                  ? 'Skip for now'
                                  : _buildButtonLabel(county),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  if (!_joinedCounty && !_joinedGeneral)
                    Center(
                      child: Text(
                        'You can join communities later from the Community tab',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11,
                            color: AppColors.gray400, fontFamily: 'Poppins'),
                      ),
                    ),
                ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  COMMUNITY CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle, tag;
  final Color tagColor;
  final List<String> features;
  final bool joined;
  final VoidCallback onToggle;

  const _CommunityCard({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.tag, required this.tagColor,
    required this.features, required this.joined,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: joined
                ? iconColor.withValues(alpha: 0.5)
                : AppColors.gray200,
            width: joined ? 2 : 1),
        boxShadow: [
          BoxShadow(
              color: joined
                  ? iconColor.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Top row — icon + title + join button
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: joined
                    ? iconColor.withValues(alpha: 0.10)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  color: joined ? iconColor : AppColors.gray400, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppColors.dark,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11,
                            color: AppColors.gray400, fontFamily: 'Poppins')),
                    const SizedBox(height: 6),
                    // Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(tag,
                          style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w600, color: tagColor,
                              fontFamily: 'Poppins')),
                    ),
                  ]),
            ),
            const SizedBox(width: 10),
            // Join toggle button
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: joined ? iconColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor, width: 1.5),
                ),
                child: Text(
                  joined ? '✓ Joined' : 'Join',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: joined ? Colors.white : iconColor),
                ),
              ),
            ),
          ]),

          // Features — only show when joined
          if (joined) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.gray100),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(children: [
                Icon(Icons.check_circle_rounded,
                    size: 14, color: iconColor),
                const SizedBox(width: 8),
                Expanded(child: Text(f,
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.gray600, fontFamily: 'Poppins'))),
              ]),
            )),
          ],
        ]),
      ),
    );
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
    width: 28, height: 28,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.3)),
    child: Center(
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: active ? AppColors.primary : Colors.white)),
    ),
  );
}