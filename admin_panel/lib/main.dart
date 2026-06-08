import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PadelFinder Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) => snapshot.data == null
            ? const AdminLoginScreen()
            : const AdminShell(),
      ),
    );
  }
}

enum VerificationState { menunggu, diterima, ditolak }

VerificationState verificationStateFromString(String? value) {
  return VerificationState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => VerificationState.menunggu,
  );
}

class AdminUser {
  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.active = true,
    this.photoUrl,
  });

  final String id;
  String name;
  String email;
  bool active;
  String? photoUrl;

  factory AdminUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminUser(
      id: doc.id,
      name: data['name'] ?? data['email'] ?? 'User',
      email: data['email'] ?? '',
      active: data['active'] != false,
      photoUrl: data['photoPath'] ?? data['photoUrl'],
    );
  }
}

class AdminTask {
  AdminTask({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    this.assignedToId,
    this.assignedToEmail,
    required this.salaryBonus,
    required this.isGeneral,
    this.status = 'pending',
  });

  final String id;
  String title;
  String description;
  String assignedTo;
  String? assignedToId;
  String? assignedToEmail;
  int salaryBonus;
  bool isGeneral;
  String status;

  factory AdminTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AdminTask(
      id: doc.id,
      title: data['title'] ?? 'Tanpa judul',
      description: data['description'] ?? '',
      assignedTo: data['assignedTo'] ?? 'Semua user',
      assignedToId: data['assignedToId'],
      assignedToEmail: data['assignedToEmail'],
      salaryBonus: (data['salaryBonus'] as num?)?.toInt() ?? 0,
      isGeneral: data['isGeneral'] == true,
      status: data['status'] ?? 'pending',
    );
  }
}

class VerificationItem {
  VerificationItem({
    required this.id,
    required this.task,
    required this.user,
    required this.note,
    this.state = VerificationState.menunggu,
  });

  final String id;
  String task;
  String user;
  String note;
  VerificationState state;

  factory VerificationItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VerificationItem(
      id: doc.id,
      task: data['taskTitle'] ?? 'Tanpa judul',
      user: data['userName'] ?? data['userEmail'] ?? 'User',
      note: data['notes'] ?? '',
      state: verificationStateFromString(data['state']),
    );
  }
}

class AdminData {
  const AdminData({
    required this.users,
    required this.tasks,
    required this.verifications,
    required this.notifications,
  });

  final List<AdminUser> users;
  final List<AdminTask> tasks;
  final List<VerificationItem> verifications;
  final List<String> notifications;
}

class AdminFirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<AdminData> watchAdminData() {
    return _db.collection('users').snapshots().asyncMap((userSnapshot) async {
      final taskSnapshot = await _db.collection('tasks').get();
      final verificationSnapshot = await _db.collection('verifications').get();
      final messageSnapshot = await _db.collection('adminMessages').get();

      final users = userSnapshot.docs
          .map(AdminUser.fromDoc)
          .where((user) => user.email != _auth.currentUser?.email)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final tasks = taskSnapshot.docs.map(AdminTask.fromDoc).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      final verifications = verificationSnapshot.docs
          .map(VerificationItem.fromDoc)
          .toList()
        ..sort((a, b) => a.task.compareTo(b.task));
      final notifications = messageSnapshot.docs
          .map((doc) => doc.data()['message'] as String? ?? '')
          .where((message) => message.isNotEmpty)
          .toList();

      return AdminData(
        users: users,
        tasks: tasks,
        verifications: verifications,
        notifications: notifications,
      );
    });
  }

  Future<void> login(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> saveAdminProfile(String name, String email, String? photo) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'photoPath': photo,
      'role': 'admin',
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> adminProfile() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data() ?? {'name': 'Admin PadelFinder', 'email': user.email};
  }

  Future<void> saveUser(AdminUser? user, String name, String email) async {
    final ref = user == null
        ? _db.collection('users').doc()
        : _db.collection('users').doc(user.id);
    await ref.set({
      'name': name,
      'email': email,
      'role': 'user',
      'active': user?.active ?? true,
      'updatedAt': FieldValue.serverTimestamp(),
      if (user == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleUser(AdminUser user) async {
    await _db.collection('users').doc(user.id).set({
      'active': !user.active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(AdminUser user) async {
    await _db.collection('users').doc(user.id).delete();
  }

  Future<void> addTask({
    required String title,
    required String description,
    required AdminUser? assignedUser,
    required bool isGeneral,
    required int salaryBonus,
  }) async {
    final now = DateTime.now();
    await _db.collection('tasks').add({
      'title': title,
      'description': description,
      'assignedTo': isGeneral ? 'Semua user' : assignedUser?.name,
      'assignedToId': isGeneral ? null : assignedUser?.id,
      'assignedToEmail': isGeneral ? null : assignedUser?.email,
      'isGeneral': isGeneral,
      'salaryBonus': salaryBonus,
      'status': 'pending',
      'startAt': Timestamp.fromDate(now),
      'dueAt': Timestamp.fromDate(now.add(const Duration(days: 1))),
      'latitude': 0,
      'longitude': 0,
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(AdminTask task) async {
    await _db.collection('tasks').doc(task.id).delete();
  }

  Future<void> updateVerification(VerificationItem item, VerificationState state) async {
    final verificationRef = _db.collection('verifications').doc(item.id);
    final verification = await verificationRef.get();
    final taskId = verification.data()?['taskId'];
    final batch = _db.batch();
    batch.set(verificationRef, {
      'state': state.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (taskId is String && taskId.isNotEmpty) {
      batch.set(_db.collection('tasks').doc(taskId), {
        'status': state == VerificationState.diterima ? 'selesai' : 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> sendNotification(String message, {String? targetUserId}) async {
    await _db.collection('adminMessages').add({
      'message': message,
      'targetUserId': targetUserId,
      'broadcast': targetUserId == null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final adminService = AdminFirebaseService();

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    try {
      await adminService.login(email.text.trim(), password.text.trim());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: SizedBox(
              width: 420,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.teal, size: 56),
                    const SizedBox(height: 12),
                    const Text('Login Admin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 22),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email admin')),
                    const SizedBox(height: 12),
                    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: loading ? null : _login,
                      icon: const Icon(Icons.login),
                      label: Text(loading ? 'Memproses...' : 'Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah yakin ingin logout dari admin panel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) await adminService.logout();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminData>(
      stream: adminService.watchAdminData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const AdminData(users: [], tasks: [], verifications: [], notifications: []);
        final pages = [
          _DashboardPage(users: data.users, tasks: data.tasks, verifications: data.verifications, notifications: data.notifications),
          _UsersPage(users: data.users),
          _TasksPage(users: data.users, tasks: data.tasks),
          _VerificationPage(items: data.verifications),
          const _AdminProfilePage(),
        ];

        return Scaffold(
          body: Row(
            children: [
              Column(
                children: [
                  Expanded(
                    child: NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: (v) => setState(() => index = v),
                      minWidth: 86,
                      backgroundColor: Colors.teal.shade50,
                      indicatorColor: Colors.teal.shade100,
                      destinations: const [
                        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                        NavigationRailDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: Text('User')),
                        NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('Tugas')),
                        NavigationRailDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: Text('Verifikasi')),
                        NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil')),
                      ],
                    ),
                  ),
                  Container(
                    width: 86,
                    color: Colors.teal.shade50,
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton.filledTonal(
                      tooltip: 'Logout',
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                    ),
                  ),
                ],
              ),
              Expanded(child: pages[index]),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.users, required this.tasks, required this.verifications, required this.notifications});
  final List<AdminUser> users;
  final List<AdminTask> tasks;
  final List<VerificationItem> verifications;
  final List<String> notifications;

  @override
  Widget build(BuildContext context) {
    final pending = verifications.where((v) => v.state == VerificationState.menunggu).length;
    final bonus = tasks.fold<int>(0, (sum, task) => sum + task.salaryBonus);
    return _AdminScaffold(
      title: 'Dashboard Realtime',
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Wrap(
            spacing: 22,
            runSpacing: 22,
            children: [
              _MetricCard(label: 'USERS', value: '${users.length}', icon: Icons.group, color: Colors.teal),
              _MetricCard(label: 'TUGAS AKTIF', value: '${tasks.length}', icon: Icons.assignment, color: Colors.indigo),
              _MetricCard(label: 'USER AKTIF', value: '${users.where((u) => u.active).length}', icon: Icons.verified_user, color: Colors.green),
              _MetricCard(label: 'PENDING', value: '$pending', icon: Icons.pending_actions, color: Colors.orange),
              _MetricCard(label: 'BONUS', value: 'Rp$bonus', icon: Icons.payments, color: Colors.purple),
            ],
          ),
          const SizedBox(height: 26),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Grafik Ringkas Aktivitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _Bar(label: 'User', value: users.length, max: 8),
                        _Bar(label: 'Tugas', value: tasks.length, max: 8),
                        _Bar(label: 'Pending', value: pending, max: 8),
                        _Bar(label: 'Notif', value: notifications.length, max: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersPage extends StatelessWidget {
  const _UsersPage({required this.users});
  final List<AdminUser> users;

  Future<void> _showUserDialog(BuildContext context, [AdminUser? user]) async {
    final name = TextEditingController(text: user?.name ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(user == null ? 'Tambah User' : 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    await adminService.saveUser(user, name.text.trim(), email.text.trim());
    await adminService.sendNotification('Admin ${user == null ? 'menambahkan akun' : 'memperbarui profil'} user ${name.text}.', targetUserId: user?.id);
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
        title: 'Manajemen User',
        action: FilledButton.icon(onPressed: () => _showUserDialog(context), icon: const Icon(Icons.add), label: const Text('Tambah User')),
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final user = users[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: user.active ? Colors.teal.shade100 : Colors.red.shade100, child: Icon(user.active ? Icons.person : Icons.person_off)),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${user.email} • ${user.active ? 'Aktif' : 'Nonaktif'}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(onPressed: () => _showUserDialog(context, user), icon: const Icon(Icons.edit)),
                    IconButton(
                      onPressed: () async {
                        await adminService.toggleUser(user);
                        await adminService.sendNotification('Admin ${user.active ? 'menonaktifkan' : 'mengaktifkan'} user ${user.name}.', targetUserId: user.id);
                      },
                      icon: Icon(user.active ? Icons.block : Icons.check_circle),
                    ),
                    IconButton(
                      onPressed: () async {
                        await adminService.deleteUser(user);
                        await adminService.sendNotification('Admin menghapus user ${user.name}.');
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _TasksPage extends StatelessWidget {
  const _TasksPage({required this.users, required this.tasks});
  final List<AdminUser> users;
  final List<AdminTask> tasks;

  Future<void> _addTask(BuildContext context) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final bonus = TextEditingController(text: '0');
    AdminUser? assigned = users.isEmpty ? null : users.first;
    bool isGeneral = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Tugas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul tugas')),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Deskripsi')),
              SwitchListTile(
                value: isGeneral,
                title: const Text('Tugas umum + tambahan gaji'),
                onChanged: (v) => setDialogState(() => isGeneral = v),
              ),
              if (!isGeneral)
                DropdownButtonFormField<AdminUser>(
                  value: assigned,
                  items: users.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                  onChanged: (v) => setDialogState(() => assigned = v),
                  decoration: const InputDecoration(labelText: 'User per tugas'),
                ),
              TextField(controller: bonus, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tambahan gaji akhir bulan')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await adminService.addTask(
      title: title.text.trim(),
      description: description.text.trim(),
      assignedUser: assigned,
      isGeneral: isGeneral,
      salaryBonus: int.tryParse(bonus.text) ?? 0,
    );
    await adminService.sendNotification('Admin menambahkan ${isGeneral ? 'tugas umum' : 'tugas'} ${title.text} untuk ${isGeneral ? 'semua user' : assigned?.name}.', targetUserId: isGeneral ? null : assigned?.id);
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
        title: 'Manajemen Tugas',
        action: FilledButton.icon(onPressed: () => _addTask(context), icon: const Icon(Icons.add_task), label: const Text('Tambah Tugas')),
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: tasks.length,
          itemBuilder: (_, i) {
            final task = tasks[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: task.isGeneral ? Colors.green.shade100 : Colors.indigo.shade100, child: Icon(task.isGeneral ? Icons.public : Icons.assignment_ind)),
                title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${task.assignedTo} • ${task.status.toUpperCase()} • Bonus Rp${task.salaryBonus}\n${task.description}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await adminService.deleteTask(task);
                    await adminService.sendNotification('Admin menghapus tugas ${task.title}.', targetUserId: task.assignedToId);
                  },
                ),
              ),
            );
          },
        ),
      );
}

class _VerificationPage extends StatelessWidget {
  const _VerificationPage({required this.items});
  final List<VerificationItem> items;

  @override
  Widget build(BuildContext context) => _AdminScaffold(
        title: 'Verifikasi Tugas User',
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: _verificationColor(item.state).withValues(alpha: .15), child: Icon(Icons.fact_check, color: _verificationColor(item.state))),
                title: Text(item.task, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${item.user} • ${item.note}\nStatus: ${item.state.name.toUpperCase()}'),
                isThreeLine: true,
                trailing: item.state == VerificationState.menunggu
                    ? Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              await adminService.updateVerification(item, VerificationState.diterima);
                              await adminService.sendNotification('Tugas ${item.task} milik ${item.user} diterima admin.');
                            },
                            child: const Text('Terima'),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              await adminService.updateVerification(item, VerificationState.ditolak);
                              await adminService.sendNotification('Tugas ${item.task} milik ${item.user} ditolak admin.');
                            },
                            child: const Text('Tolak'),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        ),
      );
}

class _AdminProfilePage extends StatefulWidget {
  const _AdminProfilePage();

  @override
  State<_AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<_AdminProfilePage> {
  String adminName = 'Admin PadelFinder';
  String adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin@padelfinder.test';
  String? adminPhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await adminService.adminProfile();
    if (!mounted) return;
    setState(() {
      adminName = data['name'] ?? adminName;
      adminEmail = data['email'] ?? adminEmail;
      adminPhoto = data['photoPath'];
    });
  }

  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: adminName);
    final email = TextEditingController(text: adminEmail);
    String? photo = adminPhoto;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profil Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 40, backgroundImage: photo == null ? null : NetworkImage(photo), child: photo == null ? const Icon(Icons.admin_panel_settings, size: 40) : null),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    await adminService.saveAdminProfile(name.text.trim(), email.text.trim(), photo);
    setState(() {
      adminName = name.text.trim();
      adminEmail = email.text.trim();
      adminPhoto = photo;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil admin diperbarui')));
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
        title: 'Profil Admin',
        child: Center(
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 56, backgroundColor: Colors.teal.shade100, child: const Icon(Icons.admin_panel_settings, size: 56, color: Colors.teal)),
                  const SizedBox(height: 16),
                  Text(adminName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text(adminEmail),
                  const SizedBox(height: 20),
                  FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.edit), label: const Text('Edit Profil')),
                ],
              ),
            ),
          ),
        ),
      );
}

class _AdminScaffold extends StatelessWidget {
  const _AdminScaffold({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.teal.shade400, Colors.green.shade200, Colors.white], stops: const [0, .42, 1])),
        child: Column(
          children: [
            Container(
              height: 86,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              color: Colors.white.withValues(alpha: .86),
              child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))), if (action != null) action!]),
            ),
            Expanded(child: child),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 265,
        height: 130,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Icon(icon, size: 42, color: color),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .8)),
                    Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(duration: const Duration(milliseconds: 300), height: 24 + (value / max) * 170, width: 46, decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      );
}

Color _verificationColor(VerificationState state) => switch (state) {
      VerificationState.menunggu => Colors.orange,
      VerificationState.diterima => Colors.green,
      VerificationState.ditolak => Colors.red,
    };
