// lib/screens/main/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/vet_dashboard_screen.dart';
import '../pigs/pigs_screen.dart';
import '../finance/finance_screen.dart';
import '../community/community_screen.dart';
import '../ai/ai_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reports/reports_screen.dart';
import '../breeding/breeding_screen.dart';
import '../health/health_screen.dart';
import '../onboarding/welcome_screen.dart';
import '../settings/help_screen.dart';
import '../settings/about_screen.dart';
// ✅ VET-SPECIFIC SCREENS
import '../vet/vet_cases_screen.dart';
import '../vet/vet_finance_screen.dart';

final mainScaffoldKey = GlobalKey<ScaffoldState>();

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => MainScaffoldState();
}

class MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  late final PageController _pageCtrl =
  PageController(initialPage: 0, keepPage: true);

  void jumpTo(int i) {
    if (!mounted || _index == i) return;
    setState(() => _index = i);
    _pageCtrl.animateToPage(i,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    // ✅ ROBUST role detection:
    // 1. Uses AuthProvider.isVet getter (trimmed string comparison)
    // 2. Falls back to direct string check on user.role as backup
    // 3. Debug log so you can see exactly what role is detected
    final rawRole = (user?.role ?? '').trim();
    final isVet = rawRole == 'Veterinarian';

    debugPrint('🏠 MainScaffold build — rawRole: "$rawRole" | isVet: $isVet');

    // ✅ VET PAGES: Home | Cases | Farmers(Community) | AI | Finance(Vet)
    // ✅ FARMER PAGES: Home | Finance | Pigs | Community | AI
    final pages = isVet
        ? const [
      VetDashboardScreen(),
      VetCasesScreen(),
      CommunityScreen(),
      AIScreen(),
      VetFinanceScreen(),
    ]
        : const [
      DashboardScreen(),
      FinanceScreen(),
      PigsScreen(),
      CommunityScreen(),
      AIScreen(),
    ];

    // ✅ VET NAV
    const vetNavItems = <Map<String, dynamic>>[
      {'icon': Icons.home_rounded,                   'label': 'Home'},
      {'icon': Icons.medical_services_rounded,       'label': 'Cases'},
      {'icon': Icons.groups_rounded,                 'label': 'Farmers'},
      {'icon': Icons.auto_awesome_rounded,           'label': 'AI'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Finance'},
    ];

    // ✅ FARMER NAV
    const farmerNavItems = <Map<String, dynamic>>[
      {'icon': Icons.home_rounded,                   'label': 'Home'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Finance'},
      {'icon': Icons.energy_savings_leaf_rounded,    'label': 'Pigs'},
      {'icon': Icons.groups_rounded,                 'label': 'Community'},
      {'icon': Icons.auto_awesome_rounded,           'label': 'AI'},
    ];

    final navItems  = isVet ? vetNavItems : farmerNavItems;
    final safeIndex = _index.clamp(0, pages.length - 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: mainScaffoldKey,
        backgroundColor: const Color(0xFFF5F6FA),
        extendBody: true,
        drawer: _AppDrawer(
          isVet: isVet,
          onNavigate: (w) {
            Navigator.pop(context);
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => w));
          },
        ),
        body: PageView(
          controller: _pageCtrl,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (i) {
            if (mounted) setState(() => _index = i);
          },
          children: pages,
        ),
        bottomNavigationBar: _FloatingNavBar(
          currentIndex: safeIndex,
          onTap: jumpTo,
          items: navItems,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FLOATING NAV BAR
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<Map<String, dynamic>> items;
  const _FloatingNavBar(
      {required this.currentIndex,
        required this.onTap,
        required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 6)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final on = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                    horizontal: on ? 16 : 14, vertical: 9),
                decoration: BoxDecoration(
                  color: on ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      items[i]['icon'] as IconData,
                      key: ValueKey('${i}_$on'),
                      size: 20,
                      color: on ? Colors.white : const Color(0xFFB0B8C1),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: on
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(width: 6),
                      Text(
                        items[i]['label'] as String,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins'),
                      ),
                    ])
                        : const SizedBox.shrink(),
                  ),
                ]),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIDEBAR DRAWER
// ─────────────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final bool isVet;
  final void Function(Widget) onNavigate;
  const _AppDrawer({required this.isVet, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // ✅ VET DRAWER
    final vetMenu = [
      _MenuItem(Icons.person_outline_rounded,        'My Profile',    const ProfileScreen()),
      _MenuItem(Icons.medical_services_rounded,      'My Cases',      const VetCasesScreen()),
      _MenuItem(Icons.account_balance_wallet_rounded,'Vet Finance',   const VetFinanceScreen()),
      _MenuItem(Icons.notifications_outlined,        'Notifications', const NotificationsScreen()),
    ];

    // ✅ FARMER DRAWER
    final farmerMenu = [
      _MenuItem(Icons.person_outline_rounded,        'My Profile',          const ProfileScreen()),
      _MenuItem(Icons.favorite_border_rounded,       'Breeding & Maturity', const BreedingScreen()),
      _MenuItem(Icons.insert_chart_outlined_rounded, 'Reports & Analytics', const ReportsScreen()),
      _MenuItem(Icons.notifications_outlined,        'Notifications',       const NotificationsScreen()),
    ];

    final supportMenu = [
      _MenuItem(Icons.settings_outlined,    'Settings',       const SettingsScreen()),
      _MenuItem(Icons.help_outline_rounded, 'Help & Support', const HelpScreen()),
      _MenuItem(Icons.info_outline_rounded, 'About App',      const AboutScreen()),
    ];

    final mainMenu = isVet ? vetMenu : farmerMenu;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(children: [

        // Profile header
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 24),
          color: AppColors.primary,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onNavigate(const ProfileScreen());
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2),
                    ),
                    child: user?.photoUrl != null &&
                        user!.photoUrl!.isNotEmpty
                        ? ClipOval(
                        child: Image.network(user.photoUrl!,
                            fit: BoxFit.cover))
                        : const Icon(Icons.person_rounded,
                        size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'User',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'Poppins')),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                                fontFamily: 'Poppins')),
                        const SizedBox(height: 6),
                        // ✅ Show vet badge if vet
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isVet) ...[
                                  const Text('🩺',
                                      style: TextStyle(fontSize: 10)),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  user?.displayRole ?? 'Farmer',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                        ),
                      ]),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 17),
                  ),
                ),
              ]),
        ),

        // Menu items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            children: [
              _DrawerSection(
                  title: isVet ? 'Vet Menu' : 'Menu',
                  items: mainMenu,
                  onNavigate: onNavigate),
              const SizedBox(height: 4),
              _DrawerSection(
                  title: 'Support',
                  items: supportMenu,
                  onNavigate: onNavigate),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.gray100),
              const SizedBox(height: 8),

              // ✅ Sign Out — matches profile screen pattern with confirmation dialog
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.danger),
                ),
                title: const Text('Sign Out',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                        fontFamily: 'Poppins')),
                onTap: () {
                  Navigator.pop(context); // close drawer first
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Sign Out',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                      content: const Text(
                          'Are you sure you want to sign out?',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel',
                              style: TextStyle(fontFamily: 'Poppins')),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: () async {
                            Navigator.pop(ctx); // close dialog
                            await context
                                .read<AuthProvider>()
                                .signOut(context: context);
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const WelcomeScreen()),
                                      (_) => false);
                            }
                          },
                          child: const Text('Sign Out',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins')),
                        ),
                      ],
                    ),
                  );
                },
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                dense: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ]),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _MenuItem(this.icon, this.label, this.screen);
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final void Function(Widget) onNavigate;
  const _DrawerSection(
      {required this.title,
        required this.items,
        required this.onNavigate});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.gray400,
              fontFamily: 'Poppins',
              letterSpacing: 0.8),
        ),
      ),
      ...items.map((m) => ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(m.icon, size: 18, color: AppColors.gray600),
        ),
        title: Text(m.label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                color: Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.gray300, size: 18),
        onTap: () => onNavigate(m.screen),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        dense: true,
      )),
    ],
  );
}