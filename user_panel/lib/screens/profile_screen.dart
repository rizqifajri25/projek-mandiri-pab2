import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../utils/helpers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ref.read(firebaseBackendProvider).getProfile();
    final currentEmail = ref.read(firebaseBackendProvider).currentUser?.email;

    if (data != null) {
      ref.read(userProfileProvider.notifier).state = UserProfile(
        name: data['name'] ?? 'User',
        email: data['email'] ?? currentEmail ?? 'user@gmail.com',
        photoPath: data['photoPath'],
      );
    }
  }

  Future<void> _pickProfilePhoto(UserProfile profile) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final updated = profile.copyWith(photoPath: file.path);
    ref.read(userProfileProvider.notifier).state = updated;
    await ref.read(firebaseBackendProvider).saveProfile(
          name: updated.name,
          photoPath: updated.photoPath,
        );
    if (mounted) SnackbarHelper.show(context, 'Foto profil diperbarui');
  }

  Future<void> _editProfile(UserProfile profile) async {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String? selectedPhoto = profile.photoPath;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: _imageProvider(selectedPhoto),
                      child: selectedPhoto == null ? const Icon(Icons.person, size: 42) : null,
                    ),
                    IconButton.filled(
                      onPressed: () async {
                        final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (file != null) setDialogState(() => selectedPhoto = file.path);
                      },
                      icon: const Icon(Icons.camera_alt, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama lengkap')),
                const SizedBox(height: 10),
                TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru (opsional)')),
                const SizedBox(height: 10),
                TextField(controller: confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi password')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    if (password.isNotEmpty && password != confirmPassword) {
      if (mounted) SnackbarHelper.show(context, 'Konfirmasi password harus sama');
      return;
    }

    try {
      final updated = profile.copyWith(
        name: nameController.text.trim().isEmpty ? profile.name : nameController.text.trim(),
        email: emailController.text.trim().isEmpty ? profile.email : emailController.text.trim(),
        photoPath: selectedPhoto,
      );

      if (updated.email != profile.email) {
        await ref.read(firebaseBackendProvider).updateEmail(updated.email);
      }
      if (password.isNotEmpty) {
        await ref.read(firebaseBackendProvider).changePassword(password);
      }
      await ref.read(firebaseBackendProvider).saveProfile(name: updated.name, photoPath: updated.photoPath);
      ref.read(userProfileProvider.notifier).state = updated;
      if (mounted) SnackbarHelper.show(context, 'Profil berhasil diperbarui');
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Gagal memperbarui profil: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firebaseBackendProvider).logout();
      ref.read(authTokenProvider.notifier).state = null;
      if (mounted) SnackbarHelper.show(context, 'Logout berhasil');
    }
  }

  ImageProvider? _imageProvider(String? path) {
    if (path == null) return null;
    if (path.startsWith('http') || path.startsWith('blob:') || kIsWeb) return NetworkImage(path);
    return NetworkImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade700, Colors.green.shade300, Colors.white],
            stops: const [0, .36, 1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text('Profil Saya', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .94), borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundImage: _imageProvider(profile.photoPath),
                          child: profile.photoPath == null ? const Icon(Icons.person, size: 54) : null,
                        ),
                        IconButton.filled(
                          onPressed: () => _pickProfilePhoto(profile),
                          icon: const Icon(Icons.camera_alt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(profile.email, style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _editProfile(profile),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profil'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileTile(icon: Icons.badge, title: 'Role', subtitle: 'Field Officer'),
              _ProfileTile(icon: Icons.verified_user, title: 'Status', subtitle: 'Aktif dan siap menerima tugas'),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: SwitchListTile(
                  value: ref.watch(darkModeProvider),
                  title: const Text('Dark mode'),
                  secondary: const Icon(Icons.dark_mode),
                  onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                  onTap: _logout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
