import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/models/user_model.dart';

class AuthMethods {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Email + password signup using Firebase Auth and Firestore.
  Future<User> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? firebaseUser = cred.user;
      if (firebaseUser == null) {
        throw Exception('Signup failed. Please try again.');
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'isGuest': false,
      });

      return User.registered(
        id: firebaseUser.uid,
        email: email,
        name: name,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Signup failed. Please try again.');
    } catch (e) {
      throw Exception('Signup failed. Please try again.');
    }
  }

  /// Email + password login using Firebase Auth.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? firebaseUser = cred.user;
      if (firebaseUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      // Read profile from Firestore (if present) to get name.
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      final data = doc.data();
      final name = (data?['name'] as String?) ?? (firebaseUser.email ?? '').split('@').first;

      return User.registered(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        name: name,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed. Please try again.');
    } catch (e) {
      throw Exception('Login failed. Please try again.');
    }
  }

  /// Google sign‑in using Firebase Auth and Firestore.
  Future<User?> signInWithGoogle() async {
    try {
      /// STEP 1 — Pick Google account
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      /// STEP 2 — Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      /// STEP 3 — Create firebase credential
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      /// STEP 4 — Firebase login
      final fb.UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final fb.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      /// STEP 5 — Firestore user check
      final userDoc =
          _firestore.collection('users').doc(firebaseUser.uid);

      final snapshot = await userDoc.get();

      /// STEP 6 — First time user (VERY IMPORTANT)
      if (!snapshot.exists) {
        await userDoc.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? "User",
          'photo': firebaseUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isGuest': false,
        });
      }

      /// STEP 7 — return app user model
      return User.registered(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? "",
        name: firebaseUser.displayName ?? "User",
        // photoUrl: firebaseUser.photoURL,
      );
    } catch (e) {
      print("GOOGLE SIGN IN ERROR: $e");
      return null;
    }
  }
}
