import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode
import 'package:google_sign_in/google_sign_in.dart';
import 'package:unlock/models/user_model.dart';
import 'package:unlock/services/firestore_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();
  static final _firestore = FirestoreService();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode)
          print(
            '[AuthService.signInWithGoogle] Google sign in cancelled by user.',
          );
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        if (kDebugMode)
          print(
            '[AuthService.signInWithGoogle] Firebase user is null after credential sign in.',
          );
        return null;
      }

      // Delegate Firestore user creation/fetching to the specialized method
      return await getOrCreateUserInFirestore(firebaseUser);
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService.signInWithGoogle] Error: $e');
      }
      return null;
    }
  }

  static Future<UserModel?> getOrCreateUserInFirestore(User user) async {
    try {
      // Check if user exists in Firestore
      final UserModel? existingUser = await _firestore.getUser(user.uid);
      if (existingUser != null) {
        if (kDebugMode) {
          print(
            '[AuthService.getOrCreateUserInFirestore] User ${user.uid} data successfully fetched: ${existingUser.username}',
          );
        }
        return existingUser;
      }

      // Create new user if not found
      if (kDebugMode) {
        print(
          '[AuthService.getOrCreateUserInFirestore] User ${user.uid} not found. Creating new document.',
        );
      }
      final newUser = UserModel(
        uid: user.uid,
        username: user.displayName ?? 'Anonimo',
        displayName: user.displayName ?? 'Anonimo',
        avatar: user.photoURL ?? '👨', // Default avatar
        email: user.email ?? '',
        level: 1,
        xp: 0,
        coins: 200, // Initial coins
        gems: 20, // Initial gems
        createdAt: DateTime.now(),
        aiConfig: {
          'apiUrl': '',
          'apiKey': '',
          'enabled': false,
        }, // Default AI config
      );

      await _firestore.createUser(newUser);
      if (kDebugMode) {
        print(
          '[AuthService.getOrCreateUserInFirestore] New user ${newUser.username} (ID: ${newUser.uid}) created.',
        );
      }
      return newUser;
    } catch (e) {
      if (kDebugMode) {
        print(
          '[AuthService.getOrCreateUserInFirestore] Error for user ${user.uid}: $e',
        );
      }
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
