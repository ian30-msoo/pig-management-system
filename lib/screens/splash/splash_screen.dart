// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/providers.dart';
import '../onboarding/welcome_screen.dart';
import '../main/main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _pulse;

  // Dark theme matching the login/signup header gradient
  static const Color _bgTop    = Color(0xFF1A1A2E);
  static const Color _bgBottom = Color(0xFF0F0F1A);
  static const Color _accent   = Color(0xFFE8253F); // your app's primary red

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.4, 0.9, curve: Curves.easeIn)),
    );
    _textSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _entryController,
          curve: const Interval(0.4, 0.9, curve: Curves.easeOut)),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    FlutterNativeSplash.remove();
    _entryController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final results = await Future.wait([
      _doAuthCheck(),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    final screen = results[0] as Widget;
    _go(screen);
  }

  Future<Widget> _doAuthCheck() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return const WelcomeScreen();

      if (!mounted) return const WelcomeScreen();
      final auth = context.read<app_auth.AuthProvider>();
      await auth.loadUser();
      if (!mounted) return const WelcomeScreen();

      if (auth.user != null) {
        final uid    = firebaseUser.uid;
        final county = auth.user?.displayCounty ?? '';
        context.read<PigProvider>().init();
        context.read<FinanceProvider>().init(uid);
        context.read<CommunityProvider>().init();
        context.read<ForumProvider>().init(county);
      }

      return auth.user?.onboardingComplete == true
          ? const MainScaffold()
          : const WelcomeScreen();
    } catch (_) {
      return const WelcomeScreen();
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, __) => screen,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_entryController, _pulseController]),
              builder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // ── Logo ────────────────────────────────────────────
                  Transform.scale(
                    scale: _iconScale.value *
                        (_entryController.isCompleted ? _pulse.value : 1.0),
                    child: Opacity(
                      opacity: _iconOpacity.value,
                      child: Stack(alignment: Alignment.center, children: [
                        // Outer glow ring
                        Container(
                          width: 128, height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                        ),
                        // Middle ring
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                        ),
                        // Icon container — dark card with red accent border
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF252535),
                            border: Border.all(color: _accent.withValues(alpha: 0.55), width: 2),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 42, height: 42,
                              child: CustomPaint(painter: _PigIconPainter(color: _accent)),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ── App name + tagline ───────────────────────────────
                  Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: Column(children: [
                        RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                              text: 'Pig',
                              style: TextStyle(
                                fontSize: 38, fontWeight: FontWeight.w800,
                                color: Colors.white, letterSpacing: -0.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            TextSpan(
                              text: 'Track',
                              style: TextStyle(
                                fontSize: 38, fontWeight: FontWeight.w800,
                                color: _accent, letterSpacing: -0.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                          ),
                          child: const Text(
                            'SMART PIG FARMING',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: Colors.white60, letterSpacing: 2.5,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 64),

                  // ── Animated loading dots ────────────────────────────
                  Opacity(
                    opacity: _textOpacity.value,
                    child: _LoadingDots(accentColor: _accent),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PIG ICON PAINTER  (clean SVG-style pig face)
// ─────────────────────────────────────────────────────────────────────────────

class _PigIconPainter extends CustomPainter {
  final Color color;
  const _PigIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill..color = color;
    final strokePaint = Paint()..style = PaintingStyle.stroke..color = color..strokeWidth = w * 0.055..strokeCap = StrokeCap.round;

    // Head (main circle)
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.36, paint);

    // Ears (two small circles top)
    canvas.drawCircle(Offset(w * 0.22, h * 0.22), w * 0.13, paint);
    canvas.drawCircle(Offset(w * 0.78, h * 0.22), w * 0.13, paint);

    // Face — white cutout (snout + eye area)
    final facePaint = Paint()..color = const Color(0xFF252535);
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.29, facePaint);

    // Snout
    canvas.drawCircle(Offset(w * 0.5, h * 0.60), w * 0.17, paint);

    // Nostrils
    final nostrilPaint = Paint()..color = const Color(0xFF252535);
    canvas.drawCircle(Offset(w * 0.42, h * 0.62), w * 0.04, nostrilPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.62), w * 0.04, nostrilPaint);

    // Eyes
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(Offset(w * 0.36, h * 0.43), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.43), w * 0.055, eyePaint);

    // Eye shine
    final shinePaint = Paint()..color = const Color(0xFF252535);
    canvas.drawCircle(Offset(w * 0.38, h * 0.41), w * 0.022, shinePaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.41), w * 0.022, shinePaint);

    // Curly tail (right side arc)
    final path = Path();
    path.moveTo(w * 0.84, h * 0.46);
    path.cubicTo(w * 1.0, h * 0.38, w * 1.02, h * 0.60, w * 0.90, h * 0.62);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOADING DOTS
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  final Color accentColor;
  const _LoadingDots({required this.accentColor});

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
      final a = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
      _controllers.add(c);
      _animations.add(a);
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) c.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(3, (i) => AnimatedBuilder(
      animation: _animations[i],
      builder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.accentColor.withValues(alpha: _animations[i].value),
        ),
      ),
    )),
  );
}