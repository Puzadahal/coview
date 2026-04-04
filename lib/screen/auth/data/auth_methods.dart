import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/models/user_model.dart';

class AuthMethods {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      await firebaseUser.updateDisplayName(name);

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
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'This email is already registered. Please login instead.',
          );
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        case 'operation-not-allowed':
          throw Exception(
            'Email/password accounts are disabled for this project. Enable them in Firebase Auth settings.',
          );
        case 'weak-password':
          throw Exception('The password is too weak. Please choose a stronger one.');
        default:
          throw Exception(e.message ?? 'Signup failed. Please try again.');
      }
    } catch (e) {
      throw Exception('Unexpected signup error. Please try again.');
    }
  }

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

      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      final data = doc.data();
      final name = (data?['name'] as String?) ?? (firebaseUser.email ?? '').split('@').first;

      return User.registered(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        name: name,
      );
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          throw Exception('Invalid email or password.');
        case 'invalid-email':
          throw Exception('The email address is not valid.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception(e.message ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      throw Exception('Unexpected login error. Please try again.');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final fb.UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final fb.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? 'User',
          'photo': firebaseUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isGuest': false,
        });
      }

      return User.registered(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? 'User',
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'This email already exists with another sign-in method. Use that method first.',
        );
      }
      throw Exception(e.message ?? 'Google sign-in failed (${e.code}).');
    } catch (e) {
      final message = e.toString();
      debugPrint('GOOGLE SIGN IN ERROR: $message');

      if (message.contains('ApiException: 10') ||
          message.contains('DEVELOPER_ERROR') ||
          message.contains('Unknown calling package name')) {
        throw Exception(
          'Google sign-in is misconfigured (DEVELOPER_ERROR). Add Android OAuth SHA fingerprints in Firebase, download a new google-services.json, then rebuild.',
        );
      }

      throw Exception('Google sign-in failed. $message');
    }
  }
}
