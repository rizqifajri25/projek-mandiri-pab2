import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_models.dart';

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

    final existingProfile = await getProfile();

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'photoPath': photoPath,
      'email': user.email,
      'role': 'user',
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
      if (existingProfile == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Stream<List<FieldTask>> streamTasks() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection('tasks').snapshots().map((snapshot) {
      final email = user.email?.toLowerCase();
      final tasks = snapshot.docs
          .map(FieldTask.fromFirestore)
          .where((task) {
            final assignedEmail = task.assignedToEmail?.toLowerCase();
            return task.isGeneral ||
                task.assignedToId == user.uid ||
                (email != null && assignedEmail == email);
          })
          .toList()
        ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
      return tasks;
    });
  }

  Future<List<FieldTask>> fetchTasks() async {
    return streamTasks().first;
  }

  Stream<List<VerificationRecord>> streamVerificationHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('verifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map(VerificationRecord.fromFirestore)
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return records;
    });
  }

  Stream<List<String>> streamAdminMessages() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore.collection('adminMessages').snapshots().map((snapshot) {
      final messages = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['broadcast'] == true || data['targetUserId'] == user.uid;
      }).toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'];
          final bDate = b.data()['createdAt'];
          if (aDate is Timestamp && bDate is Timestamp) {
            return bDate.compareTo(aDate);
          }
          return 0;
        });

      return messages
          .map((doc) => doc.data()['message'] as String? ?? '')
          .where((message) => message.isNotEmpty)
          .toList();
    });
  }

  Future<void> submitVerification({
    required FieldTask task,
    required VerificationRecord record,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final profile = await getProfile();
    final batch = _firestore.batch();
    final verificationRef = _firestore.collection('verifications').doc(record.id);
    batch.set(verificationRef, {
      'taskId': task.id,
      'taskTitle': task.title,
      'userId': user.uid,
      'userName': profile?['name'] ?? user.email ?? 'User',
      'userEmail': user.email,
      'startedAt': Timestamp.fromDate(record.startedAt),
      'completedAt': Timestamp.fromDate(record.completedAt),
      'photoPath': record.photoPath,
      'latitude': record.latitude,
      'longitude': record.longitude,
      'notes': record.notes,
      'state': 'menunggu',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(_firestore.collection('tasks').doc(task.id), {
      'status': 'diproses',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<UserCredential> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final username = email.split('@').first;
    await saveProfile(name: username);
    return credential;
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
