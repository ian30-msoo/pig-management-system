import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/common/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<app_auth.AuthProvider>();
    final ok = await auth.sendPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(auth.error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
        ]),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<app_auth.AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20, right: 20, bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18)),
                ),
                const SizedBox(height: 16),
                Container(width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 28)),
                const SizedBox(height: 14),
                const Text('Reset Password',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text("We'll send a reset link to your email",
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), fontFamily: 'Poppins')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, size.height * 0.05, 22, MediaQuery.of(context).padding.bottom + 24),
              child: _sent
                  ? _SuccessView(email: _emailCtrl.text)
                  : _FormView(form: _form, emailCtrl: _emailCtrl, loading: auth.loading, onSubmit: _send),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> form;
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSubmit;
  const _FormView({required this.form, required this.emailCtrl, required this.loading, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.info_rounded, color: AppColors.primary, size: 20)),
              const SizedBox(width: 12),
              const Expanded(child: Text(
                  'Enter the email address linked to your PigTrack account.',
                  style: TextStyle(fontSize: 13, color: AppColors.primary, fontFamily: 'Poppins', height: 1.4))),
            ]),
          ),
          const SizedBox(height: 24),
          AppCard(padding: const EdgeInsets.all(18), child: Column(children: [
            AppTextField(
              label: 'Email Address', hint: 'you@email.com',
              controller: emailCtrl, keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_rounded, size: 18, color: AppColors.gray400),
              validator: AppValidators.email,
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Send Reset Link', icon: Icons.send_rounded, loading: loading, onPressed: onSubmit),
          ])),
          const SizedBox(height: 24),
          Center(child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Back to Sign In',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Poppins', fontSize: 14)),
            ]),
          )),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 20),
      Container(width: 90, height: 90,
          decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.success)),
      const SizedBox(height: 24),
      const Text('Email Sent!',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Poppins', color: AppColors.dark)),
      const SizedBox(height: 10),
      Text('We sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.5)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(14)),
        child: const Row(children: [
          Icon(Icons.tips_and_updates_rounded, color: AppColors.warning, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text("Check your spam/junk folder if you don't see the email.",
              style: TextStyle(fontSize: 12, color: AppColors.warning, fontFamily: 'Poppins', height: 1.4))),
        ]),
      ),
      const SizedBox(height: 28),
      PrimaryButton(label: 'Back to Sign In', icon: Icons.login_rounded, onPressed: () => Navigator.pop(context)),
    ]);
  }
}