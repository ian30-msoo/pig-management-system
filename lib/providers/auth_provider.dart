// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'providers.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────────────
  UserModel? get user    => _user;
  bool       get loading => _loading;
  String?    get error   => _error;
  bool get isLoggedIn    => FirebaseAuth.instance.currentUser != null;
  String? get uid        => FirebaseAuth.instance.currentUser?.uid;

  // ✅ Convenience getter — safely returns the role string (never null).
  // main_scaffold.dart uses: (user?.role ?? '') == 'Veterinarian'
  // This getter makes it easy to check anywhere in the app.
  bool get isVet => (_user?.role ?? '').trim() == 'Veterinarian';
  bool get isFarmer => (_user?.role ?? '').trim() == 'Pig Farmer';

  void _setLoading(bool v)  { _loading = v; notifyListeners(); }
  void _setError(String? v) { _error   = v; notifyListeners(); }
  void clearError()         { _error   = null; notifyListeners(); }

  // ── LOAD USER ──────────────────────────────────────────────────────────────
  Future<void> loadUser() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    _user = await _authService.getUserData(currentUid);
    // ✅ DEBUG: log what role was loaded from Firestore
    debugPrint('🔄 loadUser() — uid: $currentUid | role: "${_user?.role}" | county: "${_user?.displayCounty}"');
    notifyListeners();
  }

  // ── SIGN UP ────────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required BuildContext context,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      _setLoading(true); _setError(null);
      await _authService.signUp(
        email: email, password: password,
        firstName: firstName, lastName: lastName, phone: phone,
      );
      await loadUser();
      if (context.mounted) _initProviders(context);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── SIGN IN ────────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true); _setError(null);

      // ✅ Reset all provider data before signing in new user
      if (context.mounted) _resetProviders(context);

      await _authService.signIn(email: email, password: password);
      await loadUser();

      // ✅ Init providers for the newly signed-in user
      if (context.mounted) _initProviders(context);

      debugPrint('✅ signIn() complete — role: "${_user?.role}" | isVet: $isVet');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── GOOGLE SIGN-IN ─────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle({required BuildContext context}) async {
    try {
      _setLoading(true); _setError(null);

      // ✅ Reset before switching account
      if (context.mounted) _resetProviders(context);

      final result = await _authService.signInWithGoogle();
      if (result == null) { _setLoading(false); return false; }
      await loadUser();

      if (context.mounted) _initProviders(context);

      debugPrint('✅ signInWithGoogle() complete — role: "${_user?.role}" | isVet: $isVet');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── FORGOT PASSWORD ────────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true); _setError(null);
      await _authService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────
  Future<void> signOut({required BuildContext context}) async {
    // ✅ CRITICAL: Reset all providers BEFORE signing out.
    if (context.mounted) _resetProviders(context);

    await _authService.signOut();
    _user = null;
    debugPrint('🚪 signOut() — user cleared');
    notifyListeners();
  }

  // ── UPDATE PROFILE ─────────────────────────────────────────────────────────
  /// ✅ Saves profile fields to Firestore and immediately reloads the user
  /// so that role/county are available in memory right after this call.
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final currentUid = uid;
    if (currentUid == null) { _setError('Not signed in.'); return false; }
    try {
      _setLoading(true); _setError(null);
      await _authService.updateUserProfile(currentUid, data);
      // ✅ CRITICAL: reload so _user reflects the new role immediately
      await loadUser();
      debugPrint('✅ updateProfile() — new role: "${_user?.role}" | isVet: $isVet');
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── UPDATE PASSWORD ────────────────────────────────────────────────────────
  Future<bool> updatePassword(String currentPass, String newPass) async {
    try {
      _setLoading(true); _setError(null);
      await _authService.updateUserPassword(currentPass, newPass);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── COMPLETE ONBOARDING ────────────────────────────────────────────────────
  Future<bool> completeOnboarding(Map<String, dynamic> extra) async {
    final currentUid = uid;
    if (currentUid == null) return false;
    try {
      _setLoading(true); _setError(null);
      await _authService.completeOnboarding(currentUid, extra);
      await loadUser();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally { _setLoading(false); }
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  /// ✅ Wipes all provider state immediately.
  void _resetProviders(BuildContext context) {
    try { context.read<PigProvider>().reset();       } catch (_) {}
    try { context.read<FinanceProvider>().reset();   } catch (_) {}
    try { context.read<CommunityProvider>().reset(); } catch (_) {}
    try { context.read<ForumProvider>().reset();     } catch (_) {}
  }

  /// ✅ Initialises all providers for the currently signed-in user.
  void _initProviders(BuildContext context) {
    final currentUid = uid;
    final county     = _user?.displayCounty ?? '';
    if (currentUid == null) return;

    try { context.read<PigProvider>().init();               } catch (_) {}
    try { context.read<FinanceProvider>().init(currentUid); } catch (_) {}
    try { context.read<CommunityProvider>().init();         } catch (_) {}
    try { context.read<ForumProvider>().init(county);       } catch (_) {}
  }
}