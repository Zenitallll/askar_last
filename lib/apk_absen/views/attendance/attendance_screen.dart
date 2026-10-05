import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import '../maps_screen.dart';
import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/app_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {

  Position? currentPosition;

  bool isLoading = false;
  bool isCheckInLoading = false;
  bool isCheckOutLoading = false;
  bool isIzinLoading = false;

  String locationAddress = 'Mendeteksi lokasi...';

  final Geocoding geocoding = Geocoding(locale: const Locale('id', 'ID'));

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      locationAddress = 'Mendeteksi lokasi...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          locationAddress = 'GPS belum aktif';
          isLoading = false;
        });

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          locationAddress = 'Izin lokasi ditolak';
          isLoading = false;
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          locationAddress = 'Izin lokasi ditolak permanen';
          isLoading = false;
        });

        return;
      }

      final position = await Geolocator.getCurrentPosition();

      String addressText = 'Lokasi PPKD JU';

      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = [
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
          ].whereType<String>().toList();

          if (parts.isNotEmpty) {
            addressText = parts.join(', ');
          }
        }
      } catch (_) {
        addressText = 'Lokasi PPKD JU';
      }

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        locationAddress = addressText;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        locationAddress = 'Gagal mendapatkan lokasi';
        isLoading = false;
      });
    }
  }

  Future<void> checkIn() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi GPS belum tersedia')),
      );

      return;
    }

    setState(() {
      isCheckInLoading = true;
    });

    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token login tidak ditemukan')),
        );

        return;
      }

      final response = await ApiServices().checkIn(
        token: token,
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        address: locationAddress,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Check In berhasil')));

        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;

      String message = 'Check In gagal';

      if (error.toString().contains('409')) {
        message = 'Anda sudah melakukan absensi hari ini';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          isCheckInLoading = false;
        });
      }
    }
  }

  Future<void> checkOut() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi GPS belum tersedia')),
      );

      return;
    }

    setState(() {
      isCheckOutLoading = true;
    });

    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token login tidak ditemukan')),
        );

        return;
      }

      final response = await ApiServices().checkOut(
        token: token,
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        address: locationAddress,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Check Out berhasil')));

        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Check Out gagal: $error')));
    } finally {
      if (mounted) {
        setState(() {
          isCheckOutLoading = false;
        });
      }
    }
  }

  Future<void> izinSakit() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi GPS belum tersedia')),
      );

      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final p = AppColors.of(dialogContext);

        return buildAppDialog(
          dialogContext,
          title: 'Izin sakit',
          message:
              'Apakah kamu yakin ingin mengajukan '
              'izin sakit hari ini?',
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
              label: 'Ajukan',
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

    setState(() {
      isIzinLoading = true;
    });

    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token login tidak ditemukan')),
        );

        return;
      }

      final response = await ApiServices().izinSakit(
        token: token,
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        address: locationAddress,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin sakit berhasil diajukan')),
        );

        Navigator.pop(context);
      }
    } catch (error) {
      if (!mounted) return;

      String message = 'Izin sakit gagal diajukan';

      if (error.toString().contains('409')) {
        message = 'Anda sudah melakukan absensi atau izin hari ini';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          isIzinLoading = false;
        });
      }
    }
  }

  void openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoogleMapsScreenDay19()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: buildAppBar(context, title: const Text('Kehadiran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(p),

            const SizedBox(height: 22),

            _buildLocationCard(p),

            const SizedBox(height: 16),

            _buildMapButton(p),

            const SizedBox(height: 34),

            Text('Aksi absensi', style: AppText.title(p.ink)),

            const SizedBox(height: 3),

            Text(
              'Pilih aktivitas yang ingin kamu lakukan',
              style: AppText.caption(p.muted),
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              title: 'Check In',
              icon: Icons.login_rounded,
              backgroundColor: p.mint,
              foregroundColor: p.onBlock,
              loading: isCheckInLoading,
              onPressed: isCheckInLoading || isCheckOutLoading || isIzinLoading
                  ? null
                  : checkIn,
            ),

            const SizedBox(height: 14),

            _buildActionButton(
              title: 'Check Out',
              icon: Icons.logout_rounded,
              backgroundColor: p.sky,
              foregroundColor: p.onBlock,
              loading: isCheckOutLoading,
              onPressed: isCheckInLoading || isCheckOutLoading || isIzinLoading
                  ? null
                  : checkOut,
            ),

            const SizedBox(height: 14),

            _buildIzinButton(p),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette p) {
    final now = DateTime.now();

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Absensi\nhari ini', style: AppText.display(p.ink).copyWith(fontSize: 46)),
        const SizedBox(height: 14),
        Sticker(
          label: '${now.day} ${months[now.month - 1]} ${now.year}',
          color: p.lemon,
          angle: -0.03,
        ),
      ],
    );
  }

  Widget _buildLocationCard(AppPalette p) {
    final success = currentPosition != null;

    return BrutalBox(
      padding: EdgeInsets.zero,
      radius: 20,
      shadow: 5,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                BlockIcon(
                  icon: Icons.location_on_rounded,
                  color: p.lemon,
                  size: 46,
                  iconSize: 23,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lokasi PPKD JU', style: AppText.heading(p.ink)),
                      Text('Lokasi GPS saat ini', style: AppText.caption(p.muted)),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                BrutalIconButton(
                  icon: Icons.refresh_rounded,
                  size: 42,
                  tooltip: 'Perbarui lokasi',
                  loading: isLoading,
                  onTap: isLoading ? null : getCurrentLocation,
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.sky,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded, color: p.onBlock, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locationAddress,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(p.onBlock).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (currentPosition != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCoordinate(
                      p,
                      'Latitude',
                      currentPosition!.latitude.toStringAsFixed(6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCoordinate(
                      p,
                      'Longitude',
                      currentPosition!.longitude.toStringAsFixed(6),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          const ThickDivider(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: success ? p.mint : p.surface,
            child: Row(
              children: [
                Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.location_searching_rounded,
                  color: success ? p.onBlock : p.ink,
                  size: 22,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        success
                            ? 'Lokasi berhasil ditemukan'
                            : 'Mencari lokasi...',
                        style: TextStyle(
                          color: success ? p.onBlock : p.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        success
                            ? 'GPS siap digunakan untuk absensi'
                            : 'Mohon tunggu sebentar',
                        style: AppText.caption(success ? p.onBlock : p.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinate(AppPalette p, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.lilac,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.caption(p.onBlock)),
          Text(value, style: AppText.figures(p.onBlock, size: 13)),
        ],
      ),
    );
  }

  Widget _buildMapButton(AppPalette p) {
    return BrutalButton(
      label: 'Lihat lokasi saya di peta',
      icon: Icons.map_rounded,
      color: p.surface,
      foreground: p.ink,
      onPressed: openMap,
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required bool loading,
    required VoidCallback? onPressed,
  }) {
    return BrutalButton(
      label: title,
      icon: icon,
      color: backgroundColor,
      foreground: foregroundColor,
      loading: loading,
      onPressed: onPressed,
      height: 78,
      fontSize: 22,
      alignStart: true,
      showArrow: true,
    );
  }

  Widget _buildIzinButton(AppPalette p) {
    return BrutalButton(
      label: isIzinLoading ? 'Mengajukan izin...' : 'Izin sakit',
      icon: Icons.sick_rounded,
      color: p.coral,
      foreground: p.onBlock,
      loading: isIzinLoading,
      onPressed: isCheckInLoading || isCheckOutLoading || isIzinLoading
          ? null
          : izinSakit,
      height: 64,
      fontSize: 18,
      alignStart: true,
      showArrow: true,
    );
  }
}
