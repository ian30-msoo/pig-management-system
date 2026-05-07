// lib/screens/auth/signin_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/common/widgets.dart';
import '../main/main_scaffold.dart';
import '../onboarding/onboard1_screen.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form      = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _showPass   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<app_auth.AuthProvider>();

    final ok = await auth.signIn(
      context:  context,
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      _navigateAfterLogin();
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  Future<void> _googleSignIn() async {
    final auth = context.read<app_auth.AuthProvider>();
    final ok = await auth.signInWithGoogle(context: context);

    if (!mounted) return;
    if (ok) {
      _navigateAfterLogin();
    } else if (auth.error != null) {
      _showError(auth.error!);
      auth.clearError();
    }
  }

  void _navigateAfterLogin() {
    final auth = context.read<app_auth.AuthProvider>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => auth.user?.onboardingComplete == true
            ? const MainScaffold()
            : const Onboard1Screen(),
      ),
          (_) => false,
    );
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
              child: const Icon(Icons.login_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins', letterSpacing: -0.3),
            ),
            const SizedBox(height: 5),
            Text(
              'Sign in to your account',
              style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.78), fontFamily: 'Poppins', fontWeight: FontWeight.w400),
            ),
          ]),
        ),

        // ── Form ─────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, size.height * 0.04, 20, MediaQuery.of(context).padding.bottom + 28),
            child: Form(
              key: _form,
              child: Column(children: [

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

                // ── Password ──────────────────────────────────────────
                _FieldCard(
                  label: 'Password',
                  child: _StyledTextField(
                    hint: 'password',
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

                // ── Forgot password ───────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6)),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // ── Submit ────────────────────────────────────────────
                PrimaryButton(
                  label: 'Sign In',
                  icon: Icons.arrow_forward_rounded,
                  loading: auth.loading,
                  onPressed: _submit,
                ),

                const SizedBox(height: 24),
                _DividerOr(),
                const SizedBox(height: 18),

                // ── Google ────────────────────────────────────────────
                _GoogleButton(loading: auth.loading, onPressed: _googleSignIn),

                const SizedBox(height: 26),

                // ── Sign up link ──────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account?  ", style: TextStyle(color: AppColors.gray600, fontFamily: 'Poppins', fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontFamily: 'Poppins', fontSize: 14)),
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
//  SHARED WIDGETS (same as signup_screen.dart)
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
        child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF374151), fontFamily: 'Poppins', letterSpacing: 0.1)),
      ),
      child,
    ],
  );
}

class _StyledTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    required this.prefixIcon,
    this.suffixWidget,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.8)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.danger, width: 1.8)),
      errorStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5),
    ),
    validator: validator,
  );
}

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
        const Text('Continue with Google', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF3C4043), fontFamily: 'Poppins')),
      ]),
    ),
  );
}

class _RealGoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    const blue   = Color(0xFF4285F4);
    const red    = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green  = Color(0xFF34A853);

    final center = Offset(s / 2, s / 2);
    final r = s / 2;

    canvas.clipRect(Rect.fromLTWH(0, 0, s, s));

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = red;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 3.49, 1.83, true, paint);
    paint.color = yellow;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 2.36, 1.13, true, paint);
    paint.color = green;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 1.26, 1.10, true, paint);
    paint.color = blue;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -0.30, 1.56, true, paint);

    canvas.drawCircle(center, r * 0.56, Paint()..color = Colors.white);

    paint.color = blue;
    canvas.drawRect(Rect.fromLTWH(center.dx - r * 0.04, center.dy - r * 0.20, r * 1.04, r * 0.40), paint);
    canvas.drawCircle(center, r * 0.56, Paint()..color = Colors.white);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.56),
      -0.32, 0.64, false,
      Paint()..color = blue..style = PaintingStyle.stroke..strokeWidth = r * 0.40,
    );
    canvas.drawCircle(center, r * 0.38, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_) => false;
}