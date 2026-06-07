import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseBackendService {
  final _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;
  Stream<User?> authState() => _auth.authStateChanges();

  Future<void> saveProfile({
    required String name,
    String? photoPath,
  }) async {
    final user = _auth.currentUser;

    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'name': name,
      'photoPath': photoPath,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data();
  }

  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');
    await user.updatePassword(newPassword);
  }

  Future<void> updateEmail(String email) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');
    await user.verifyBeforeUpdateEmail(email);
    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> refreshToken() async {
    await _auth.currentUser?.getIdToken(true);
  }

  Future<void> logout() => _auth.signOut();
}