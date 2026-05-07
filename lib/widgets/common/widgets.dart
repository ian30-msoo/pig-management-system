// lib/widgets/common/widgets.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// ─── PRIMARY BUTTON ────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double? width;
  final Color? color;

  const PrimaryButton({
    super.key, required this.label, this.onPressed,
    this.loading = false, this.icon, this.width, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          disabledBackgroundColor: (color ?? AppColors.primary).withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          shadowColor: (color ?? AppColors.primary).withOpacity(0.3),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                ],
              ),
      ),
    );
  }
}

// ─── OUTLINE BUTTON ────────────────────────────────────────────────────────
class OutlineButton2 extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const OutlineButton2({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

// ─── CUSTOM TEXT FIELD ─────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscure;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool enabled;
  final Function(String)? onChanged;
  final TextCapitalization capitalization;

  const AppTextField({
    super.key, required this.label, this.hint, this.controller,
    this.validator, this.obscure = false, this.suffixIcon, this.prefixIcon,
    this.keyboardType, this.maxLines = 1, this.enabled = true,
    this.onChanged, this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          textCapitalization: capitalization,
          style: const TextStyle(fontSize: 14, color: AppColors.dark, fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ─── APP CARD ──────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key, required this.child, this.padding,
    this.radius, this.color, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radius ?? 20),
      shadowColor: Colors.black.withOpacity(0.08),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius ?? 20),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ─── STATUS BADGE ──────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({super.key, required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'Poppins')),
    );
  }
}

// ─── LOADING OVERLAY ───────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;

  const LoadingOverlay({super.key, required this.loading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ─── SECTION HEADER ────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins')),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Poppins')),
          ),
      ],
    );
  }
}

// ─── AVATAR ICON ───────────────────────────────────────────────────────────
class AvatarIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color iconColor;
  final Color bgColor;

  const AvatarIcon({
    super.key, required this.icon, this.size = 46,
    this.iconColor = AppColors.primary, this.bgColor = AppColors.primaryBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.44, color: iconColor),
    );
  }
}

// ─── GOOGLE BUTTON ─────────────────────────────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool loading;

  const GoogleSignInButton({super.key, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.gray200),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEA4335)),
                    child: const Icon(Icons.g_mobiledata_rounded, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Text('Continue with Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark, fontFamily: 'Poppins')),
                ],
              ),
      ),
    );
  }
}

// ─── EMPTY STATE ───────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key, required this.icon, required this.title,
    required this.subtitle, this.actionLabel, this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: AppColors.primaryBg, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.gray400, fontFamily: 'Poppins'), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── STAT CARD ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? badge;

  const StatCard({
    super.key, required this.label, required this.value,
    required this.icon, required this.color, required this.bgColor, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AvatarIcon(icon: icon, size: 38, iconColor: color, bgColor: bgColor),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success, fontFamily: 'Poppins')),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, fontFamily: 'Poppins')),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray400, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// ─── DIVIDER WITH TEXT ─────────────────────────────────────────────────────
class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.gray400, fontFamily: 'Poppins')),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}
