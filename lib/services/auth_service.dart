import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);
    // Create user profile in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'isVolunteer': false,
      'fcmToken': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  Future<UserCredential> login(
      {required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> logout() async => await _auth.signOut();

  Future<void> updateFcmToken(String token) async {
    if (currentUid == null) return;
    await _db
        .collection('users')
        .doc(currentUid)
        .update({'fcmToken': token});
  }
}