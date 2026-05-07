import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── No serverClientId needed for Firebase Auth ─────────────────────────────
  // Just register your debug SHA-1 in Firebase Console and it works.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ══════════════════════════════════════════════════════════════════════════
  // SIGN UP
  // ══════════════════════════════════════════════════════════════════════════
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = cred.user!;
      await firebaseUser.updateDisplayName('$firstName $lastName'.trim());

      final model = UserModel(
        uid: firebaseUser.uid,
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
        role: 'Farmer',
        county: '',
        farmName: '',
        farmSize: '',
        communities: [],
        onboardingComplete: false,
        createdAt: DateTime.now(),
      );
      await _saveUserToFirestore(model);
      return model;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      throw 'Sign up failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIGN IN
  // ══════════════════════════════════════════════════════════════════════════
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await getUserData(_auth.currentUser!.uid);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      throw 'Sign in failed. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ══════════════════════════════════════════════════════════════════════════
  Future<UserModel?> signInWithGoogle() async {
    GoogleSignInAccount? googleUser;
    try {
      // Force account picker every time
      await _googleSignIn.signOut();
      googleUser = await _googleSignIn.signIn();

      // User pressed back / cancelled — return null silently
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      // idToken is null when SHA-1 is missing or wrong google-services.json
      if (googleAuth.idToken == null) {
        throw 'Setup incomplete: missing ID token. '
            'Please download the latest google-services.json from Firebase Console '
            '(after adding your SHA-1 fingerprint) and replace android/app/google-services.json.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final firebaseUser = cred.user!;

      // Return existing Firestore profile if already registered
      final existing = await getUserData(firebaseUser.uid);
      if (existing != null) return existing;

      // New Google user — create their profile
      final nameParts = (firebaseUser.displayName ?? '').trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final model = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: firstName,
        lastName: lastName,
        phone: firebaseUser.phoneNumber ?? '',
        photoUrl: firebaseUser.photoURL,
        role: 'Farmer',
        county: '',
        farmName: '',
        farmSize: '',
        communities: [],
        onboardingComplete: false,
        createdAt: DateTime.now(),
      );
      await _saveUserToFirestore(model);
      return model;
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      final msg = e.toString();

      // ApiException 10 = SHA-1 not registered OR wrong google-services.json
      if (msg.contains('ApiException: 10') || msg.contains('sign_in_failed')) {
        throw 'Google Sign-In failed (error 10).\n'
            'Steps to fix:\n'
            '1. Add SHA-1 to Firebase Console → Project Settings → Your Android app\n'
            '2. Download the new google-services.json\n'
            '3. Replace android/app/google-services.json\n'
            '4. Stop and re-run the app (not hot restart)';
      }

      // Re-throw our own descriptive messages (like idToken null)
      if (msg.contains('Setup incomplete') ||
          msg.contains('SHA-1') ||
          msg.contains('ID token')) {
        rethrow;
      }

      if (msg.contains('network') || msg.contains('NETWORK_ERROR')) {
        throw 'No internet connection. Please check your network.';
      }

      // Unknown error — show the raw message for debugging
      throw 'Google Sign-In failed: $msg';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      throw 'Failed to send reset email. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GET USER DATA
  // ══════════════════════════════════════════════════════════════════════════
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromDoc(doc);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UPDATE USER PROFILE
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      final firstName = data['firstName'] as String?;
      final lastName = data['lastName'] as String?;
      if (firstName != null || lastName != null) {
        final current = await getUserData(uid);
        final f = firstName ?? current?.firstName ?? '';
        final l = lastName ?? current?.lastName ?? '';
        await _auth.currentUser?.updateDisplayName('$f $l'.trim());
      }
      final photoUrl = data['photoUrl'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _auth.currentUser?.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UPDATE PASSWORD
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> updateUserPassword(
      String currentPassword, String newPassword) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) throw 'Not signed in.';
      if (firebaseUser.email == null) {
        throw 'Cannot change password for Google accounts.';
      }
      final cred = EmailAuthProvider.credential(
        email: firebaseUser.email!,
        password: currentPassword,
      );
      await firebaseUser.reauthenticateWithCredential(cred);
      await firebaseUser.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e.code);
    } catch (e) {
      throw e.toString();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPLETE ONBOARDING
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> completeOnboarding(
      String uid, Map<String, dynamic> extra) async {
    await _db.collection('users').doc(uid).set(
      {
        'onboardingComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
        ...extra,
      },
      SetOptions(merge: true),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _saveUserToFirestore(UserModel user) async {
    await _db
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'requires-recent-login':
        return 'Please sign in again before changing your password.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}