import 'package:flutter/material.dart';

import '../../reusable/theme_controller.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import '../auth/login_screen.dart';
import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // DATA
  // ============================================================

  String name = 'Memuat...';
  String email = 'Memuat...';

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  Future<void> getUserData() async {
    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          name = '-';
          email = '-';
        });

        return;
      }

      final response = await ApiServices().getProfile(token: token);

      if (response.statusCode == 200) {
        final user = response.data['data'];

        if (!mounted) return;

        setState(() {
          name = user['name'] ?? '-';
          email = user['email'] ?? '-';
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil profile: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile() async {
    final token = await StorageServices.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nama dan email tidak boleh kosong'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );

      return;
    }

    try {
      final response = await ApiServices().updateProfile(
        token: token,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (response.statusCode == 200) {
        await StorageServices.saveUser(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
        );

        await getUserData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 9),
                Text('Profile berhasil diperbarui'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal update profile: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  void openEditProfile() {
    nameController.text = name;
    emailController.text = email;

    final sheetPalette = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        side: BorderSide(color: sheetPalette.border, width: 2),
      ),
      builder: (sheetContext) {
        final p = AppColors.of(sheetContext);

        return Padding(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 26,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Text('Edit profil', style: AppText.display(p.ink).copyWith(fontSize: 32)),

                const SizedBox(height: 4),

                Text(
                  'Perbarui informasi akun kamu',
                  style: AppText.body(p.muted),
                ),

                const SizedBox(height: 22),

                _editField(
                  controller: nameController,
                  label: 'Nama',
                  icon: Icons.person_outline_rounded,
                ),

                const SizedBox(height: 16),

                _editField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 24),

                BrutalButton(
                  label: 'Simpan perubahan',
                  color: p.lemon,
                  foreground: p.onBlock,
                  height: 56,
                  fontSize: 17,
                  showArrow: true,
                  onPressed: () async {
                    Navigator.pop(sheetContext);

                    await updateProfile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EDIT FIELD
  // ============================================================

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final p = AppColors.of(dialogContext);

        return buildAppDialog(
          dialogContext,
          title: 'Keluar dari akun?',
          message: 'Apakah kamu yakin ingin keluar dari akun?',
          actions: [
            BrutalButton(
              label: 'Batal',
              color: p.surface,
              foreground: p.ink,
              expand: false,
              height: 46,
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
            ),
            BrutalButton(
              label: 'Keluar',
              color: p.coral,
              foreground: p.onBlock,
              expand: false,
              height: 46,
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await StorageServices.removeToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // DARK MODE
  // ============================================================

  Future<void> changeTheme(bool value) async {
    ThemeController.isDarkMode.value = value;

    await StorageServices.saveTheme(value);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: p.onPrimary,
          backgroundColor: p.primary,
          onRefresh: getUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(p),

                const SizedBox(height: 22),

                _buildProfileHero(p),

                const SizedBox(height: 24),

                _buildAccountCard(p),

                const SizedBox(height: 18),

                _buildSettingsCard(p),

                const SizedBox(height: 24),

                _buildLogoutCard(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(AppPalette p) {
    return Row(
      children: [
        _circleButton(
          p,
          icon: Icons.arrow_back_rounded,
          onTap: () {
            Navigator.pop(context);
          },
        ),

        const SizedBox(width: 16),

        Expanded(child: Text('Profil', style: AppText.display(p.ink).copyWith(fontSize: 34))),

        _circleButton(p, icon: Icons.more_horiz_rounded, onTap: () {}),
      ],
    );
  }

  // ============================================================
  // PROFILE HERO
  // ============================================================

  Widget _buildProfileHero(AppPalette p) {
    return BrutalBox(
      color: p.primary,
      radius: 24,
      shadow: 7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: p.lilac,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border, width: 2.5),
                ),
                child: Image.asset(
                  'assets/image/a.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: p.lilac,
                      child: Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: p.onBlock,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(Colors.white).copyWith(fontSize: 26),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(Colors.white.withValues(alpha: 0.88)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Sticker(
                label: 'Pengguna aktif',
                icon: Icons.verified_rounded,
                color: p.mint,
                angle: -0.04,
              ),

              const Spacer(),

              BrutalButton(
                label: 'Edit',
                icon: Icons.edit_rounded,
                color: p.lemon,
                foreground: p.onBlock,
                expand: false,
                height: 42,
                fontSize: 14,
                onPressed: openEditProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CIRCLE BUTTON
  // ============================================================

  Widget _circleButton(
    AppPalette p, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return BrutalIconButton(icon: icon, onTap: onTap);
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard(AppPalette p) {
    return BrutalBox(
      padding: EdgeInsets.zero,
      radius: 20,
      shadow: 5,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(
            p,
            color: p.lilac,
            title: 'Informasi akun',
            subtitle: 'Data pribadi dan akun kamu',
          ),

          const ThickDivider(),

          _profileRow(
            p,
            icon: Icons.person_outline_rounded,
            title: 'Nama',
            value: name,
            onTap: openEditProfile,
          ),

          const ThickDivider(thickness: 1.5),

          _profileRow(
            p,
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE ROW
  // ============================================================

  Widget _profileRow(
    AppPalette p, {
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: p.ink, size: 22),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.caption(p.muted)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading(p.ink),
                  ),
                ],
              ),
            ),

            Icon(Icons.arrow_forward_rounded, color: p.ink, size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS CARD
  // ============================================================

  Widget _buildSettingsCard(AppPalette p) {
    return BrutalBox(
      padding: EdgeInsets.zero,
      radius: 20,
      shadow: 5,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardHeader(
            p,
            color: p.sky,
            title: 'Pengaturan',
            subtitle: 'Sesuaikan tampilan aplikasi',
          ),

          const ThickDivider(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<bool>(
              valueListenable: ThemeController.isDarkMode,
              builder: (context, isDarkMode, child) {
                return Row(
                  children: [
                    BlockIcon(
                      icon: isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: p.lemon,
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mode gelap', style: AppText.heading(p.ink)),
                          Text(
                            'Tampilan gelap untuk kenyamanan mata',
                            style: AppText.caption(p.muted),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: isDarkMode,
                      onChanged: changeTheme,
                      activeThumbColor: p.ink,
                      activeTrackColor: p.mint,
                      inactiveThumbColor: p.ink,
                      inactiveTrackColor: p.surface,
                      trackOutlineColor: WidgetStateProperty.all(p.border),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD HEADER
  // ============================================================

  Widget _cardHeader(
    AppPalette p, {
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.title(p.onBlock)),
          Text(subtitle, style: AppText.caption(p.onBlock)),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT CARD
  // ============================================================

  Widget _buildLogoutCard(AppPalette p) {
    return BrutalButton(
      label: 'Logout',
      icon: Icons.logout_rounded,
      color: p.coral,
      foreground: p.onBlock,
      height: 62,
      fontSize: 19,
      alignStart: true,
      showArrow: true,
      onPressed: logout,
    );
  }
}
