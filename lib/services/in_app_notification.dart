// lib/services/in_app_notification.dart
// ─────────────────────────────────────────────────────────────────────────────
//  WhatsApp-style overlay notification — shows on top of any screen
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InAppNotification {
  static OverlayEntry? _current;
  static Timer? _timer;
  static AnimationController? _controller;

  /// Show a popup notification on top of the current screen.
  /// Works from any screen by using the root overlay.
  static void show(
      BuildContext context, {
        required String title,
        required String body,
        Color color = AppColors.primary,
        IconData icon = Icons.notifications_rounded,
        VoidCallback? onTap,
        Duration duration = const Duration(seconds: 5),
      }) {
    hide(); // dismiss any existing popup first

    final overlay = Overlay.of(context, rootOverlay: true);

    _current = OverlayEntry(
      builder: (_) => _NotifBanner(
        title: title,
        body: body,
        color: color,
        icon: icon,
        onTap: () { hide(); onTap?.call(); },
        onDismiss: hide,
      ),
    );

    overlay.insert(_current!);
    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notification banner widget — slides from top like WhatsApp
// ─────────────────────────────────────────────────────────────────────────────

class _NotifBanner extends StatefulWidget {
  final String title, body;
  final Color color;
  final IconData icon;
  final VoidCallback onTap, onDismiss;

  const _NotifBanner({
    required this.title, required this.body, required this.color,
    required this.icon, required this.onTap, required this.onDismiss,
  });

  @override
  State<_NotifBanner> createState() => _NotifBannerState();
}

class _NotifBannerState extends State<_NotifBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  Future<void> _dismiss() async {
    await _ctrl.animateBack(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInCubic);
    widget.onDismiss();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragEnd: (d) { if (d.primaryVelocity != null && d.primaryVelocity! < 0) _dismiss(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6)),
                    BoxShadow(color: widget.color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text('PigTrack', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray400, fontFamily: 'Poppins')),
                    ]),
                    const SizedBox(height: 3),
                    Text(widget.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark, fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(widget.body, style: const TextStyle(fontSize: 11, color: AppColors.gray600, fontFamily: 'Poppins', height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.close_rounded, size: 14, color: AppColors.gray400),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}