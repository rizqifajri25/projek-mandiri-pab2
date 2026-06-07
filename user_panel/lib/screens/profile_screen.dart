import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_providers.dart';
import '../utils/helpers.dart';
import 'package:flutter/foundation.dart';

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
  Future<void> _changePassword() async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ganti Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password baru'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await ref
            .read(firebaseBackendProvider)
            .changePassword(controller.text.trim());
        if (mounted) SnackbarHelper.show(context, 'Password berhasil diubah');
      } catch (e) {
        if (mounted) {
          SnackbarHelper.show(context, 'Gagal ubah password: $e');
        }
      }
    }
  }

  Future<void> _loadProfile() async {
  final data =
      await ref.read(firebaseBackendProvider).getProfile();

  if (data != null) {
    ref.read(userProfileProvider.notifier).state =
        UserProfile(
      name: data['name'] ?? 'User',
      photoPath: data['photoPath'],
    );
  }
}

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(firebaseBackendProvider).logout();
      ref.read(authTokenProvider.notifier).state = null;
      if (mounted) SnackbarHelper.show(context, 'Logout berhasil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    ImageProvider? _photoProvider() {
      if (profile.photoPath == null) return null;

      final path = profile.photoPath!;

      if (path.startsWith('http') || path.startsWith('blob:')) {
        return NetworkImage(path);
      }

      if (kIsWeb) {
        return NetworkImage(path);
      }

      return NetworkImage(path);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: _photoProvider(),
                  child: profile.photoPath == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () async {
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        final updated = profile.copyWith(
                          photoPath: file.path,
                        );

                        ref.read(userProfileProvider.notifier).state =
                            updated;

                        await ref
                            .read(firebaseBackendProvider)
                            .saveProfile(
                              name: updated.name,
                              photoPath: updated.photoPath,
                            );
                      }
                    },
                    icon: const CircleAvatar(
                      child: Icon(Icons.camera_alt, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: profile.name,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
            onChanged: (v) async {
              final updated = profile.copyWith(name: v);

              ref.read(userProfileProvider.notifier).state =
                  updated;

              await ref
                  .read(firebaseBackendProvider)
                  .saveProfile(
                    name: updated.name,
                    photoPath: updated.photoPath,
                  );
            },
          ),
          const SizedBox(height: 12),
          const ListTile(
            leading: Icon(Icons.badge),
            title: Text('Role'),
            subtitle: Text('Field Officer'),
          ),
          const ListTile(
            leading: Icon(Icons.email),
            title: Text('Email'),
            subtitle: Text('Akun Firebase aktif'),
          ),
          SwitchListTile(
            value: ref.watch(darkModeProvider),
            title: const Text('Dark mode'),
            onChanged: (v) => ref.read(darkModeProvider.notifier).state = v,
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Ganti Password'),
            onTap: _changePassword,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}