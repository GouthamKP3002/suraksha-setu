import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class SafeCircleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  String get _circleBase => 'users/${_auth.currentUid}/safe_circle';

  Stream<QuerySnapshot> getCircle() {
    return _db
        .collection(_circleBase)
        .orderBy('addedAt', descending: false)
        .snapshots();
  }

  // Add any contact directly — no app account needed
  Future<String?> addMember({
    required String name,
    required String phone,
    required String email,
  }) async {
    name  = name.trim();
    phone = phone.trim();
    email = email.trim();

    if (name.isEmpty)  return 'Name is required';
    if (phone.isEmpty) return 'Phone number is required';

    // Limit 5
    final existing = await _db.collection(_circleBase).get();
    if (existing.docs.length >= 5) return 'Maximum 5 members allowed';

    // Prevent duplicate phone
    final dup = await _db
        .collection(_circleBase)
        .where('phone', isEqualTo: phone)
        .get();
    if (dup.docs.isNotEmpty) return 'This number is already in your circle';

    await _db.collection(_circleBase).add({
      'name':     name,
      'phone':    phone,
      'email':    email,   // optional but used for EmailJS
      'addedAt':  FieldValue.serverTimestamp(),
    });

    return null; // null = success
  }

  Future<void> removeMember(String docId) async {
    await _db.collection(_circleBase).doc(docId).delete();
  }
}