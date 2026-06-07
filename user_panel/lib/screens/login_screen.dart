import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../utils/helpers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool isSignUp = false;
  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      final auth = ref.read(firebaseBackendProvider);

      if (isSignUp) {
        await auth.signUp(_email.text.trim(), _password.text.trim());
      } else {
        await auth.login(_email.text.trim(), _password.text.trim());
      }

      ref.read(authTokenProvider.notifier).state = 'firebase-token';
      if (mounted) {
        SnackbarHelper.show(
          context,
          isSignUp ? 'Sign up berhasil' : 'Login berhasil',
        );
      }
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Gagal: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  isSignUp ? 'Sign Up' : 'Login',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v != null && v.contains('@')) ? null : 'Email tidak valid',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      (v != null && v.length >= 6) ? null : 'Minimal 6 karakter',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: loading ? null : _submit,
                  child: Text(
                    loading
                        ? 'Memproses...'
                        : (isSignUp ? 'Sign Up' : 'Login'),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => isSignUp = !isSignUp),
                  child: Text(
                    isSignUp
                        ? 'Sudah punya akun? Login'
                        : 'Belum punya akun? Sign Up',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}