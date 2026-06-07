import 'package:flutter/material.dart';

void main() => runApp(const AdminApp());

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PadelFinder Admin',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal, fontFamily: 'Roboto'),
      home: const AdminShell(),
    );
  }
}

enum VerificationState { menunggu, diterima, ditolak }

class AdminUser {
  AdminUser({required this.name, required this.email, this.active = true, this.photoUrl});
  String name;
  String email;
  bool active;
  String? photoUrl;
}

class AdminTask {
  AdminTask({required this.title, required this.assignedTo, required this.salaryBonus, required this.isGeneral});
  String title;
  String assignedTo;
  int salaryBonus;
  bool isGeneral;
}

class VerificationItem {
  VerificationItem({required this.task, required this.user, required this.note, this.state = VerificationState.menunggu});
  String task;
  String user;
  String note;
  VerificationState state;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  final users = <AdminUser>[
    AdminUser(name: 'Rizky Pratama', email: 'rizky@padel.test'),
    AdminUser(name: 'Sinta Amelia', email: 'sinta@padel.test'),
    AdminUser(name: 'Budi Santoso', email: 'budi@padel.test', active: false),
  ];
  final tasks = <AdminTask>[
    AdminTask(title: 'Inspeksi Court A', assignedTo: 'Rizky Pratama', salaryBonus: 0, isGeneral: false),
    AdminTask(title: 'Tugas umum kebersihan', assignedTo: 'Semua user', salaryBonus: 250000, isGeneral: true),
    AdminTask(title: 'Audit lampu malam', assignedTo: 'Sinta Amelia', salaryBonus: 0, isGeneral: false),
  ];
  final verifications = <VerificationItem>[
    VerificationItem(task: 'Inspeksi Court A', user: 'Rizky Pratama', note: 'Foto dan lokasi sudah dikirim.'),
    VerificationItem(task: 'Tugas umum kebersihan', user: 'Sinta Amelia', note: 'Menunggu validasi bonus akhir bulan.'),
  ];
  final notifications = <String>['Admin siap memantau aktivitas user.'];
  String adminName = 'Admin PadelFinder';
  String adminEmail = 'admin@padelfinder.test';
  String? adminPhoto;

  int get activeTasks => tasks.length;
  int get pendingVerifications => verifications.where((v) => v.state == VerificationState.menunggu).length;

  void addNotification(String message) {
    setState(() => notifications.insert(0, message));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notifikasi user: $message')));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(users: users, tasks: tasks, verifications: verifications, notifications: notifications),
      _UsersPage(users: users, onNotify: addNotification, refresh: () => setState(() {})),
      _TasksPage(users: users, tasks: tasks, onNotify: addNotification, refresh: () => setState(() {})),
      _VerificationPage(items: verifications, onNotify: addNotification, refresh: () => setState(() {})),
      _AdminProfilePage(
        name: adminName,
        email: adminEmail,
        photo: adminPhoto,
        onSave: (name, email, photo) => setState(() { adminName = name; adminEmail = email; adminPhoto = photo; }),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
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
          Expanded(child: pages[index]),
        ],
      ),
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
              _MetricCard(label: 'BONUS BULANAN', value: 'Rp$bonus', icon: Icons.payments, color: Colors.pink),
            ],
          ),
          const SizedBox(height: 28),
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
  const _UsersPage({required this.users, required this.onNotify, required this.refresh});
  final List<AdminUser> users;
  final ValueChanged<String> onNotify;
  final VoidCallback refresh;

  Future<void> _showUserDialog(BuildContext context, [AdminUser? user]) async {
    final name = TextEditingController(text: user?.name ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(user == null ? 'Tambah User' : 'Edit User'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan'))],
    ));
    if (ok != true) return;
    if (user == null) {
      users.add(AdminUser(name: name.text, email: email.text));
      onNotify('Admin menambahkan akun user ${name.text}.');
    } else {
      user.name = name.text; user.email = email.text;
      onNotify('Admin memperbarui profil user ${name.text}.');
    }
    refresh();
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
            trailing: Wrap(spacing: 8, children: [
              IconButton(onPressed: () => _showUserDialog(context, user), icon: const Icon(Icons.edit)),
              IconButton(onPressed: () { user.active = !user.active; onNotify('Admin ${user.active ? 'mengaktifkan' : 'menonaktifkan'} user ${user.name}.'); refresh(); }, icon: Icon(user.active ? Icons.block : Icons.check_circle)),
              IconButton(onPressed: () { final removed = users.removeAt(i); onNotify('Admin menghapus user ${removed.name}.'); refresh(); }, icon: const Icon(Icons.delete, color: Colors.red)),
            ]),
          ),
        );
      },
    ),
  );
}

class _TasksPage extends StatelessWidget {
  const _TasksPage({required this.users, required this.tasks, required this.onNotify, required this.refresh});
  final List<AdminUser> users;
  final List<AdminTask> tasks;
  final ValueChanged<String> onNotify;
  final VoidCallback refresh;

  Future<void> _addTask(BuildContext context) async {
    final title = TextEditingController();
    final bonus = TextEditingController(text: '0');
    String assigned = users.isEmpty ? 'Semua user' : users.first.name;
    bool isGeneral = false;
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Tambah Tugas'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Judul tugas')),
        SwitchListTile(value: isGeneral, title: const Text('Tugas umum + tambahan gaji'), onChanged: (v) => setDialogState(() { isGeneral = v; assigned = v ? 'Semua user' : assigned; })),
        if (!isGeneral) DropdownButtonFormField<String>(value: assigned, items: users.map((u) => DropdownMenuItem(value: u.name, child: Text(u.name))).toList(), onChanged: (v) => setDialogState(() => assigned = v ?? assigned), decoration: const InputDecoration(labelText: 'User per tugas')),
        if (isGeneral) TextField(controller: bonus, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tambahan gaji akhir bulan')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan'))],
    )));
    if (ok != true) return;
    tasks.add(AdminTask(title: title.text, assignedTo: assigned, salaryBonus: int.tryParse(bonus.text) ?? 0, isGeneral: isGeneral));
    onNotify('Admin menambahkan ${isGeneral ? 'tugas umum' : 'tugas'} ${title.text} untuk $assigned.');
    refresh();
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Manajemen Tugas',
    action: FilledButton.icon(onPressed: () => _addTask(context), icon: const Icon(Icons.add_task), label: const Text('Tambah Tugas')),
    child: ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tasks.length,
      itemBuilder: (_, i) { final task = tasks[i]; return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: task.isGeneral ? Colors.green.shade100 : Colors.indigo.shade100, child: Icon(task.isGeneral ? Icons.public : Icons.assignment_ind)),
          title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${task.assignedTo} • Bonus Rp${task.salaryBonus}'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { final removed = tasks.removeAt(i); onNotify('Admin menghapus tugas ${removed.title}.'); refresh(); }),
        ),
      ); },
    ),
  );
}

class _VerificationPage extends StatelessWidget {
  const _VerificationPage({required this.items, required this.onNotify, required this.refresh});
  final List<VerificationItem> items;
  final ValueChanged<String> onNotify;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Verifikasi Tugas User',
    child: ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (_, i) { final item = items[i]; return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: _verificationColor(item.state).withValues(alpha: .15), child: Icon(Icons.fact_check, color: _verificationColor(item.state))),
          title: Text(item.task, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${item.user} • ${item.note}\nStatus: ${item.state.name.toUpperCase()}'),
          isThreeLine: true,
          trailing: item.state == VerificationState.menunggu ? Wrap(spacing: 8, children: [
            FilledButton(onPressed: () { item.state = VerificationState.diterima; onNotify('Tugas ${item.task} milik ${item.user} diterima admin.'); refresh(); }, child: const Text('Terima')),
            OutlinedButton(onPressed: () { item.state = VerificationState.ditolak; onNotify('Tugas ${item.task} milik ${item.user} ditolak admin.'); refresh(); }, child: const Text('Tolak')),
          ]) : null,
        ),
      ); },
    ),
  );
}

class _AdminProfilePage extends StatefulWidget {
  const _AdminProfilePage({required this.name, required this.email, required this.photo, required this.onSave});
  final String name;
  final String email;
  final String? photo;
  final void Function(String name, String email, String? photo) onSave;

  @override
  State<_AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<_AdminProfilePage> {
  Future<void> _edit(BuildContext context) async {
    final name = TextEditingController(text: widget.name);
    final email = TextEditingController(text: widget.email);
    final password = TextEditingController();
    final confirm = TextEditingController();
    String? photo = widget.photo;
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Edit Profil Admin'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 40, backgroundImage: photo == null ? null : NetworkImage(photo!), child: photo == null ? const Icon(Icons.admin_panel_settings, size: 40) : null),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama')),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru')),
        TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi password')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan'))],
    ));
    if (ok != true) return;
    if (password.text.isNotEmpty && password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password admin harus sama')));
      return;
    }
    widget.onSave(name.text, email.text, photo);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil admin diperbarui')));
  }

  @override
  Widget build(BuildContext context) => _AdminScaffold(
    title: 'Profil Admin',
    child: Center(child: Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 56, backgroundColor: Colors.teal.shade100, child: const Icon(Icons.admin_panel_settings, size: 56, color: Colors.teal)),
        const SizedBox(height: 16),
        Text(widget.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        Text(widget.email),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.edit), label: const Text('Edit Profil')),
      ])),
    )),
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
    child: Column(children: [
      Container(
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        color: Colors.white.withValues(alpha: .86),
        child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))), if (action != null) action!]),
      ),
      Expanded(child: child),
    ]),
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
      child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [
        Icon(icon, size: 42, color: color),
        const SizedBox(width: 18),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .8)),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        ]),
      ])),
    ),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) => Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
    AnimatedContainer(duration: const Duration(milliseconds: 300), height: 24 + (value / max) * 170, width: 46, decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(20))),
    const SizedBox(height: 8),
    Text(label),
  ]));
}

Color _verificationColor(VerificationState state) => switch (state) {
  VerificationState.menunggu => Colors.orange,
  VerificationState.diterima => Colors.green,
  VerificationState.ditolak => Colors.red,
};
