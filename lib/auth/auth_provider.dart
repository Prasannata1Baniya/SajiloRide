import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProviderMethod extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  AuthProviderMethod() {
    _auth.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }

  // --- FETCH ROLE ---
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String;
      }
      return 'passenger';
    } catch (e) {
      return 'passenger';
    }
  }

  // --- LOGIN ---
  Future<String?> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    }
  }

  // --- REGISTER ---
  Future<String> signUpWithEmailAndPassword(
      String name, String email, String password,String phone,String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? firebaseUser = result.user;

      await firebaseUser!.updateDisplayName(name);

      String dummyLicenseUrl = "";

      if (role.toLowerCase() == 'driver') {
        dummyLicenseUrl = "https://cdn-icons-png.flaticon.com/512/3524/3524752.png";
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'name': name,
        'email': email,
        'phone':phone,
        'role': role.toLowerCase(),
        'licenseImageUrl': dummyLicenseUrl,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'Success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}