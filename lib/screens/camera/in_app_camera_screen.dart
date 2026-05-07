// lib/screens/camera/in_app_camera_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  IN-APP CAMERA  (WhatsApp-style — opens inside your app, no native crash)
//  ✅ FIXED: Uses XFile + Image.memory everywhere — works on Flutter Web too.
//
//  Usage:
//    final XFile? photo = await Navigator.push(
//      context,
//      MaterialPageRoute(builder: (_) => const InAppCamera()),
//    );
//    if (photo != null) { /* use photo */ }
// ─────────────────────────────────────────────────────────────────────────────

class InAppCamera extends StatefulWidget {
  const InAppCamera({super.key});

  @override
  State<InAppCamera> createState() => _InAppCameraState();
}

class _InAppCameraState extends State<InAppCamera>
    with WidgetsBindingObserver {
  CameraController? _ctrl;
  List<CameraDescription> _cameras = [];

  bool  _initializing = true;
  bool  _capturing    = false;
  bool  _flash        = false;
  int   _camIndex     = 0; // 0 = back, 1 = front

  XFile?    _preview;      // photo preview after capture
  Uint8List? _previewBytes; // decoded bytes for Image.memory

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(index: _camIndex);
    }
  }

  Future<void> _initCamera({int index = 0}) async {
    setState(() {
      _initializing = true;
      _preview      = null;
      _previewBytes = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _initializing = false);
        return;
      }
      final cam = _cameras[index.clamp(0, _cameras.length - 1)];
      final ctrl = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (mounted) {
        await _ctrl?.dispose();
        _ctrl = ctrl;
        setState(() {
          _camIndex     = index;
          _initializing = false;
        });
      } else {
        await ctrl.dispose();
      }
    } catch (_) {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    await _initCamera(index: _camIndex == 0 ? 1 : 0);
  }

  Future<void> _toggleFlash() async {
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final next = !_flash;
    await ctrl.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    setState(() => _flash = next);
  }

  Future<void> _capture() async {
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final xfile = await ctrl.takePicture(); // ✅ XFile — works on all platforms
      final bytes = await xfile.readAsBytes(); // ✅ read bytes for Image.memory
      if (mounted) {
        setState(() {
          _preview      = xfile;
          _previewBytes = bytes;
          _capturing    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked != null && mounted) {
      Navigator.pop(context, picked); // ✅ return XFile directly
    }
  }

  void _retake() => setState(() {
    _preview      = null;
    _previewBytes = null;
  });

  void _confirm() {
    if (_preview != null) Navigator.pop(context, _preview); // ✅ return XFile
  }

  void _close() => Navigator.pop(context, null);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl?.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _preview != null && _previewBytes != null
          ? _PreviewScreen(
        bytes:     _previewBytes!,
        onRetake:  _retake,
        onConfirm: _confirm,
      )
          : _CameraScreen(
        ctrl:         _ctrl,
        initializing: _initializing,
        cameras:      _cameras,
        capturing:    _capturing,
        flash:        _flash,
        onClose:      _close,
        onFlip:       _flipCamera,
        onFlash:      _toggleFlash,
        onCapture:    _capture,
        onGallery:    _pickFromGallery,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CAMERA VIEWFINDER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _CameraScreen extends StatelessWidget {
  final CameraController? ctrl;
  final bool initializing, capturing, flash;
  final List<CameraDescription> cameras;
  final VoidCallback onClose, onFlip, onFlash, onCapture, onGallery;

  const _CameraScreen({
    required this.ctrl,
    required this.initializing,
    required this.cameras,
    required this.capturing,
    required this.flash,
    required this.onClose,
    required this.onFlip,
    required this.onFlash,
    required this.onCapture,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Stack(fit: StackFit.expand, children: [

      // ── Camera Preview ────────────────────────────────────────────────
      if (!initializing && ctrl != null && ctrl!.value.isInitialized)
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: 1 / ctrl!.value.aspectRatio,
            child: CameraPreview(ctrl!),
          ),
        )
      else
        const Center(child: CircularProgressIndicator(color: Colors.white)),

      // ── Top bar ───────────────────────────────────────────────────────
      Positioned(
        top: mq.padding.top + 12,
        left: 16, right: 16,
        child: Row(children: [
          _CamBtn(icon: Icons.close_rounded, onTap: onClose),
          const Spacer(),
          _CamBtn(
            icon: flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            onTap: onFlash,
            active: flash,
          ),
        ]),
      ),

      // ── Bottom controls ───────────────────────────────────────────────
      Positioned(
        bottom: mq.padding.bottom + 24,
        left: 0, right: 0,
        child: Column(children: [
          const Text(
            'Tap the button to take a photo',
            style: TextStyle(
              fontSize: 12, color: Colors.white60,
              fontFamily: 'Poppins', letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Gallery button
                _CamBtn(
                  icon: Icons.photo_library_rounded,
                  onTap: onGallery,
                  size: 52,
                ),

                // Shutter
                GestureDetector(
                  onTap: capturing ? null : onCapture,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: capturing ? 68 : 76,
                    height: capturing ? 68 : 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: capturing ? 44 : 58,
                        height: capturing ? 44 : 58,
                        decoration: BoxDecoration(
                          color: capturing
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: capturing
                            ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2),
                        )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Flip camera
                _CamBtn(
                  icon: Icons.flip_camera_ios_rounded,
                  onTap: cameras.length > 1 ? onFlip : null,
                  size: 52,
                ),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PHOTO PREVIEW SCREEN
//  ✅ FIXED: Uses Image.memory(bytes) instead of Image.file — works on web.
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewScreen extends StatelessWidget {
  final Uint8List    bytes;
  final VoidCallback onRetake, onConfirm;

  const _PreviewScreen({
    required this.bytes,
    required this.onRetake,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Stack(fit: StackFit.expand, children: [

      // ✅ Full-screen preview — Image.memory works on web AND mobile
      Positioned.fill(child: Image.memory(bytes, fit: BoxFit.cover)),

      // Gradient scrim at bottom
      Positioned(
        bottom: 0, left: 0, right: 0,
        height: 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
            ),
          ),
        ),
      ),

      // Gradient scrim at top
      Positioned(
        top: 0, left: 0, right: 0,
        height: 120,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
            ),
          ),
        ),
      ),

      // Top: retake button
      Positioned(
        top: mq.padding.top + 12,
        left: 16,
        child: _CamBtn(
          icon: Icons.arrow_back_rounded,
          onTap: onRetake,
          label: 'Retake',
        ),
      ),

      // Bottom: Use Photo button
      Positioned(
        bottom: mq.padding.bottom + 28,
        left: 24, right: 24,
        child: GestureDetector(
          onTap: onConfirm,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 22, color: Colors.black87),
                SizedBox(width: 10),
                Text(
                  'Use This Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CAMERA ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _CamBtn extends StatelessWidget {
  final IconData    icon;
  final VoidCallback? onTap;
  final bool        active;
  final double      size;
  final String?     label;

  const _CamBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size   = 46,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          border:
          Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(
          icon,
          size: size * 0.46,
          color: active ? Colors.black : Colors.white,
        ),
      ),
    );

    if (label == null) return btn;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      btn,
      const SizedBox(height: 4),
      Text(label!,
          style: const TextStyle(
              fontSize: 11, color: Colors.white70, fontFamily: 'Poppins')),
    ]);
  }
}