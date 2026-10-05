import 'package:askar_last/apk_absen/services/api_services.dart';
import 'package:askar_last/apk_absen/services/storage_services.dart';
import 'package:askar_last/apk_absen/views/dashboard/dashboard_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';


import 'register_screen.dart';
import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final ApiServices apiService = ApiServices();

  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        final user = response.data['data']['user'];

        await StorageServices.saveToken(token);

        await StorageServices.saveUser(
          name: user['name'],
          email: user['email'],
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }

      ('Response login: ${response.data}');
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Login gagal';

      if (e.response != null) {
        message = e.response?.data.toString() ?? 'Terjadi kesalahan API';
      } else {
        message = 'Tidak dapat terhubung ke server';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      backgroundColor: p.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan bentuk geometris
                SizedBox(
                  height: 214,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 6,
                        top: 0,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: p.mint,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.border, width: 2.5),
                          ),
                        ),
                      ),

                      Positioned(
                        right: 70,
                        top: 52,
                        child: Transform.rotate(
                          angle: 0.35,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: p.lemon,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: p.border, width: 2.5),
                            ),
                          ),
                        ),
                      ),

                      const Positioned(
                        left: 0,
                        top: 0,
                        child: _LoginMark(),
                      ),

                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Text(
                          'Selamat\ndatang\nkembali',
                          style: AppText.display(Colors.white).copyWith(
                            fontSize: 44,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Masuk ke akun absensi kamu.',
                  style: AppText.body(Colors.white.withValues(alpha: 0.9)),
                ),

                const SizedBox(height: 26),

                BrutalBox(
                  radius: 22,
                  shadow: 7,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email wajib diisi';
                            }

                            if (!value.contains('@')) {
                              return 'Masukkan email yang valid';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: isPasswordVisible
                                  ? 'Sembunyikan kata sandi'
                                  : 'Tampilkan kata sandi',
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password wajib diisi';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Tombol Login
                        BrutalButton(
                          label: 'Masuk',
                          color: p.lemon,
                          foreground: p.onBlock,
                          height: 56,
                          fontSize: 18,
                          loading: isLoading,
                          showArrow: true,
                          onPressed: isLoading ? null : login,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun?',
                      style: AppText.body(Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Daftar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo kecil di header login.
class _LoginMark extends StatelessWidget {
  const _LoginMark();

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return BlockIcon(
      icon: Icons.fingerprint_rounded,
      color: p.lemon,
      size: 58,
      iconSize: 32,
    );
  }
}
