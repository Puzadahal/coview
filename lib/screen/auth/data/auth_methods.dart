import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/models/user_model.dart';

class AuthMethods {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
