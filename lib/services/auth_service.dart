import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  // Use getters to prevent crashing if Firebase is not initialized yet
  FirebaseAuth? get _auth => Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;
  
  final _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth?.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isPinSet => _settingsBox.get('pin') != null;

  late Box _settingsBox;

  Future<void> init() async {
    _settingsBox = Hive.box('settings');
    notifyListeners();
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Sign-in cancelled';

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_auth == null) {
        return 'Firebase is not initialized. Please configure Firebase first.';
      }

      await _auth!.signInWithCredential(credential);

      // Save user to Firestore in background (fire-and-forget, never blocks login)
      _saveUserToFirestore();

      notifyListeners();
      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }

  /// Saves user profile to Firestore for the admin panel.
  /// Fire-and-forget with a timeout — never blocks the UI.
  void _saveUserToFirestore() {
    final user = currentUser;
    if (user == null || _firestore == null) return;

    _firestore!
        .collection('users')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'name': user.displayName ?? 'Unknown',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'lastSignIn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5))
        .catchError((e) {
          debugPrint('Firestore save skipped: $e');
        });
  }

  // ── Passwordless Email Link Sign-In ─────────────────────────────────────────

  Future<String?> sendEmailLink(String email) async {
    if (_auth == null) return 'Firebase is not initialized.';
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://budgetplanner.page.link/email-login',
        handleCodeInApp: true,
        androidPackageName: 'com.budgetplanner.expense_tracker',
        androidInstallApp: true,
        androidMinimumVersion: '12',
      );

      await _auth!.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // Save the email locally so you don't need to ask the user for it again
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);

      return null; // null = success
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> completeEmailSignIn(String emailLink) async {
    if (_auth == null) return 'Firebase is not initialized.';
    try {
      if (_auth!.isSignInWithEmailLink(emailLink)) {
        final prefs = await SharedPreferences.getInstance();
        String? email = prefs.getString('emailForSignIn');

        if (email == null) {
          return 'Email address not found. Please try logging in again.';
        }

        await _auth!.signInWithEmailLink(email: email, emailLink: emailLink);
        
        await prefs.remove('emailForSignIn');

        // Save user to Firestore in background (fire-and-forget)
        _saveUserToFirestore();

        notifyListeners();
        return null; // null = success
      }
      return 'Invalid or expired email link.';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth?.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      await _googleSignIn.signOut().timeout(const Duration(seconds: 5));
    } catch (_) {}
    _settingsBox.delete('pin'); // Clear PIN on sign-out
    notifyListeners();
  }

  // ── PIN Management ──────────────────────────────────────────────────────────
  void setPin(String pin) {
    _settingsBox.put('pin', pin);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    final stored = _settingsBox.get('pin');
    return stored != null && stored == pin;
  }

  String? getStoredPin() => _settingsBox.get('pin');

  // ── Admin check (by email) ──────────────────────────────────────────────────
  bool get isAdmin {
    final email = currentUser?.email ?? '';
    // Add your own admin email here
    return email.contains('admin') || email == 'asima@gmail.com';
  }
}
