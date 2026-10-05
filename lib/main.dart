import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/theme_controller.dart';
import 'package:askar_last/apk_absen/services/storage_services.dart';
import 'package:askar_last/apk_absen/views/auth/login_screen.dart';
import 'package:flutter/material.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedTheme = await StorageServices.getTheme();

  ThemeController.isDarkMode.value = savedTheme;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'APK Absensi',

          theme: AppTheme.light,

          darkTheme: AppTheme.dark,

          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

          home: const LoginScreen(),
        );
      },
    );
  }
}
