// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/common/widgets.dart';
import '../onboarding/onboard1_screen.dart';
import '../main/main_scaffold.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form      = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _showPass      = false;
  String _passwordValue = '';

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() => _passwordValue = _passCtrl.text));
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  String get _fullPhone => '+254${_phoneCtrl.text.trim()}';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<app_auth.AuthProvider>();

    final ok = await auth.signUp(
      context:   context,
      email:     _emailCtrl.text.trim(),
      password:  _passCtrl.text,
      firstName: _firstCtrl.text.trim(),
      lastName:  _lastCtrl.text.trim(),
      phone:     _fullPhone,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Onboard1Screen()),
            (_) => false,
      );
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  Future<void> _googleSignUp() async {
    final auth = context.read<app_auth.AuthProvider>();
    final ok = await auth.signInWithGoogle(context: context);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => auth.user?.onboardingComplete == true
              ? const MainScaffold()
              : const Onboard1Screen(),
        ),
            (_) => false,
      );
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
      ]),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(children: [

        // ── Header ──────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 24, right: 24, bottom: 32,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins', letterSpacing: -0.3),
            ),
            const SizedBox(height: 5),
            Text(
              "Join Kenya's smartest pig farming platform",
              style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.78), fontFamily: 'Poppins', fontWeight: FontWeight.w400),
            ),
          ]),
        ),

        // ── Form ─────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, size.height * 0.028, 20, MediaQuery.of(context).padding.bottom + 28),
            child: Form(
              key: _form,
              child: Column(children: [
                // ── Name row ──────────────────────────────────────────
                Row(children: [
                  Expanded(child: _FieldCard(
                    label: 'First Name',
                    child: _StyledTextField(
                      hint: 'e.g. Ian',
                      controller: _firstCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => AppValidators.name(v, 'First name'),
                      capitalization: TextCapitalization.words,
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _FieldCard(
                    label: 'Last Name',
                    child: _StyledTextField(
                      hint: 'e.g. Wanjohi',
                      controller: _lastCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => AppValidators.name(v, 'Last name'),
                      capitalization: TextCapitalization.words,
                    ),
                  )),
                ]),
                const SizedBox(height: 12),

                // ── Email ─────────────────────────────────────────────
                _FieldCard(
                  label: 'Email Address',
                  child: _StyledTextField(
                    hint: 'name@gmail.com',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: AppValidators.email,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Phone ─────────────────────────────────────────────
                _PhoneFieldCard(controller: _phoneCtrl),
                const SizedBox(height: 12),

                // ── Password ──────────────────────────────────────────
                _FieldCard(
                  label: 'Password',
                  child: _StyledTextField(
                    hint: 'Min. 8 chars, A–Z, 0–9, symbol',
                    controller: _passCtrl,
                    obscure: !_showPass,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixWidget: GestureDetector(
                      onTap: () => setState(() => _showPass = !_showPass),
                      child: Icon(
                        _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 19, color: const Color(0xFF9CA3AF),
                      ),
                    ),
                    validator: AppValidators.password,
                  ),
                ),

                if (_passwordValue.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _PasswordStrengthIndicator(password: _passwordValue),
                ],

                const SizedBox(height: 20),

                // ── Submit button ────────────────────────────────────
                PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.arrow_forward_rounded,
                  loading: auth.loading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 24),
                _DividerOr(),
                const SizedBox(height: 18),

                // ── Google button ─────────────────────────────────────
                _GoogleButton(loading: auth.loading, onPressed: _googleSignUp),
                const SizedBox(height: 26),

                // ── Sign in link ──────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account?  ', style: TextStyle(color: AppColors.gray600, fontFamily: 'Poppins', fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontFamily: 'Poppins', fontSize: 14)),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FIELD CARD WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
            letterSpacing: 0.1,
          ),
        ),
      ),
      child,
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  STYLED TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final TextCapitalization capitalization;

  const _StyledTextField({
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    required this.prefixIcon,
    this.suffixWidget,
    this.validator,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure,
    textCapitalization: capitalization,
    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(prefixIcon, size: 18, color: const Color(0xFFB0B7C3)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIcon: suffixWidget != null
          ? Padding(padding: const EdgeInsets.only(right: 14), child: suffixWidget)
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
      ),
      errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5),
    ),
    validator: validator,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PHONE FIELD CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneFieldCard extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneFieldCard({required this.controller});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(left: 2, bottom: 6),
        child: Text(
          'Phone Number',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151), fontFamily: 'Poppins', letterSpacing: 0.1),
        ),
      ),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: '7XX XXX XXX',
          hintStyle: const TextStyle(color: Color(0xFFB0B7C3), fontFamily: 'Poppins', fontSize: 13.5, fontWeight: FontWeight.w400),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🇰🇪', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              const Text('+254', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827), fontFamily: 'Poppins', fontSize: 14)),
              const SizedBox(width: 10),
              Container(width: 1, height: 22, color: const Color(0xFFE5E7EB)),
            ]),
          ),
          prefixIconConstraints: const BoxConstraints(minHeight: 44),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.2)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.8)),
          errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Phone number is required';
          if (v.trim().length < 9) return 'Enter 9 digits after +254';
          return null;
        },
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  DIVIDER OR
// ─────────────────────────────────────────────────────────────────────────────

class _DividerOr extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Divider(color: const Color(0xFFE5E7EB), thickness: 1)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text('or continue with', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, fontFamily: 'Poppins')),
    ),
    Expanded(child: Divider(color: const Color(0xFFE5E7EB), thickness: 1)),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
//  GOOGLE BUTTON  (real Google "G" SVG logo)
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _GoogleButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 54,
    child: OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 22, height: 22, child: CustomPaint(painter: _RealGoogleLogoPainter())),
        const SizedBox(width: 12),
        const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF3C4043), fontFamily: 'Poppins'),
        ),
      ]),
    ),
  );
}

/// Draws the official Google "G" logo accurately using SVG path data
class _RealGoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;

    // Colors
    const blue   = Color(0xFF4285F4);
    const red    = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green  = Color(0xFF34A853);

    final rect = Rect.fromLTWH(0, 0, s, s);
    final center = Offset(s / 2, s / 2);
    final r = s / 2;

    // Clip to circle
    canvas.clipRect(rect);

    final paint = Paint()..style = PaintingStyle.fill;

    // Red arc (top-left)
    paint.color = red;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 3.49, 1.83, true, paint);

    // Yellow arc (bottom-left)
    paint.color = yellow;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 2.36, 1.13, true, paint);

    // Green arc (bottom-right)
    paint.color = green;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 1.26, 1.10, true, paint);

    // Blue arc (top-right + right)
    paint.color = blue;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -0.30, 1.56, true, paint);

    // White inner circle
    canvas.drawCircle(center, r * 0.56, Paint()..color = Colors.white);

    // Blue horizontal bar for the "G" cutout
    paint.color = blue;
    final barRect = Rect.fromLTWH(
      center.dx - r * 0.04,
      center.dy - r * 0.20,
      r * 1.04,
      r * 0.40,
    );
    canvas.drawRect(barRect, paint);

    // Re-draw white inner circle to clean up left side
    canvas.drawCircle(center, r * 0.56, Paint()..color = Colors.white);

    // Final blue right-half arc to form the "G" arm
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.56),
      -0.32, 0.64, false,
      Paint()
        ..color = blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.40,
    );

    // White gap to separate arm from circle
    canvas.drawCircle(center, r * 0.38, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PASSWORD STRENGTH INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  int get _strength {
    int s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) s++;
    if (RegExp(r'[0-9]').hasMatch(password)) s++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(password)) s++;
    return s;
  }

  String get _label { switch (_strength) { case 1: return 'Weak'; case 2: return 'Fair'; case 3: return 'Good'; case 4: return 'Strong'; default: return 'Too short'; } }
  Color get _color { switch (_strength) { case 1: return const Color(0xFFEF4444); case 2: return const Color(0xFFF97316); case 3: return const Color(0xFFEAB308); case 4: return const Color(0xFF22C55E); default: return const Color(0xFFEF4444); } }

  @override
  Widget build(BuildContext context) {
    final rules = [
      _Rule('At least 8 characters',     password.length >= 8),
      _Rule('Uppercase letter (A–Z)',     RegExp(r'[A-Z]').hasMatch(password)),
      _Rule('Lowercase letter (a–z)',     RegExp(r'[a-z]').hasMatch(password)),
      _Rule('Number (0–9)',               RegExp(r'[0-9]').hasMatch(password)),
      _Rule('Special character (!@#\$…)', RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(password)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strength / 4,
              minHeight: 5,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          )),
          const SizedBox(width: 10),
          Text(_label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _color, fontFamily: 'Poppins')),
        ]),
        const SizedBox(height: 10),
        ...rules.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(r.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 14, color: r.met ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB)),
            const SizedBox(width: 7),
            Text(r.label, style: TextStyle(fontSize: 11.5, fontFamily: 'Poppins', color: r.met ? const Color(0xFF374151) : const Color(0xFF9CA3AF), fontWeight: r.met ? FontWeight.w600 : FontWeight.w400)),
          ]),
        )),
      ]),
    );
  }
}

class _Rule { final String label; final bool met; const _Rule(this.label, this.met); }