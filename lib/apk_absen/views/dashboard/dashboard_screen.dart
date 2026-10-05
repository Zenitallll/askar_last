import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/attendance_model.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/history_screen.dart';
import '../profile/profile_screen.dart';
import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  // =========================
  // DATA
  // =========================

  String userName = 'Pengguna';

  bool isLoading = false;
  bool isLocationLoading = false;

  List<AttendanceModel> attendanceList = [];
  AttendanceModel? todayAttendance;

  String locationAddress = 'Mencari lokasi...';

  Position? currentPosition;

  GoogleMapController? mapController;

  // Default hanya sebagai titik awal map.
  // Kalau GPS sudah berhasil, map akan otomatis pindah
  // ke lokasi GPS perangkat.
  final LatLng defaultLocation = const LatLng(-6.2000, 106.816666);

  @override
  void initState() {
    super.initState();

    loadDashboard();
    getCurrentLocation();
  }

  // =========================
  // LOAD DASHBOARD
  // =========================

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final token = await StorageServices.getToken();

      if (token == null || token.isEmpty) {
        return;
      }

      // =========================
      // PROFILE
      // =========================

      final profileResponse = await ApiServices().getProfile(token: token);

      if (profileResponse.statusCode == 200) {
        final profileData = profileResponse.data['data'];

        if (profileData != null && mounted) {
          setState(() {
            userName = profileData['name']?.toString() ?? 'Pengguna';
          });
        }
      }

      // =========================
      // HISTORY
      // =========================

      final now = DateTime.now();

      final historyResponse = await ApiServices().getHistory(
        token: token,
        start: '${now.year}-01-01',
        end: '${now.year}-12-31',
      );

      if (historyResponse.statusCode == 200) {
        final data = historyResponse.data['data'];

        if (data is List) {
          final list = data
              .map(
                (item) =>
                    AttendanceModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();

          AttendanceModel? today;

          for (final item in list) {
            if (item.checkIn != null && item.checkIn!.isNotEmpty) {
              final parsedDate = DateTime.tryParse(item.checkIn!);

              if (parsedDate != null &&
                  parsedDate.year == now.year &&
                  parsedDate.month == now.month &&
                  parsedDate.day == now.day) {
                today = item;
                break;
              }
            }
          }

          if (mounted) {
            setState(() {
              attendanceList = list;
              todayAttendance = today;
            });
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat dashboard: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================
  // GPS
  // =========================

  Future<void> getCurrentLocation() async {
    if (mounted) {
      setState(() {
        isLocationLoading = true;
        locationAddress = 'Mencari lokasi...';
      });
    }

    try {
      // Cek GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            locationAddress = 'GPS belum aktif';
            isLocationLoading = false;
          });
        }
        return;
      }

      // Cek permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            locationAddress = 'Izin lokasi ditolak';
            isLocationLoading = false;
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            locationAddress = 'Izin lokasi ditolak permanen';
            isLocationLoading = false;
          });
        }
        return;
      }

      // Ambil posisi GPS terbaru
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition = position;

        // GPS tetap asli,
        // tetapi label yang ditampilkan adalah PPKD JU.
        locationAddress = 'PPKD JU';

        isLocationLoading = false;
      });

      // Pindahkan kamera Google Maps ke GPS terbaru
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          locationAddress = 'Gagal mendapatkan lokasi';
          isLocationLoading = false;
        });
      }
    }
  }

  // =========================
  // STATISTIK
  // =========================

  int get totalAttendance {
    return attendanceList.where((item) {
      return item.status?.toLowerCase() == 'masuk';
    }).length;
  }

  int get totalCheckOut {
    return attendanceList.where((item) {
      return item.checkOut != null && item.checkOut!.isNotEmpty;
    }).length;
  }

  int get totalIzinSakit {
    return attendanceList.where((item) {
      return item.status?.toLowerCase() == 'izin';
    }).length;
  }

  String get todayStatus {
    if (todayAttendance == null) {
      return 'Belum Absen';
    }

    final status = todayAttendance!.status?.toLowerCase();

    if (status == 'izin') {
      return 'Izin Sakit';
    }

    if (status == 'masuk') {
      return 'Hadir';
    }

    return todayAttendance!.status ?? 'Belum Absen';
  }

  // =========================
  // FORMAT TANGGAL
  // =========================

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // =========================
  // MARKER GPS
  // =========================

  Set<Marker> get currentMarker {
    if (currentPosition == null) {
      return {};
    }

    return {
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Lokasi Saya', snippet: 'PPKD JU'),
      ),
    };
  }

  // =========================
  // NAVIGATION
  // =========================

  void openAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendanceScreen()),
    );
  }

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      backgroundColor: p.bg,

      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: p.onPrimary,
          backgroundColor: p.primary,
          onRefresh: () async {
            await loadDashboard();
            await getCurrentLocation();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                _buildHeader(p),

                if (isLoading) ...[
                  const SizedBox(height: 14),
                  Container(
                    height: 10,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.border, width: 2),
                    ),
                    child: LinearProgressIndicator(
                      color: p.primary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // HARI INI
                _buildTodayCard(p),

                const SizedBox(height: 18),

                // STATISTIK
                _buildStatistics(p),

                const SizedBox(height: 34),

                // LOKASI + MAP
                _buildSectionTitle(p, 'Lokasi saya', 'Posisi GPS perangkat kamu'),

                const SizedBox(height: 14),

                _buildLocationPanel(p),

                const SizedBox(height: 34),

                // RIWAYAT
                _buildHistoryHeader(p),

                const SizedBox(height: 14),

                if (attendanceList.isEmpty)
                  _buildEmptyHistory(p)
                else
                  ...attendanceList
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildHistoryCard(p, item),
                        ),
                      ),

                if (attendanceList.length > 3) _buildSeeAllButton(p),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: _buildDock(p),
    );
  }

  // =========================
  // SECTION TITLE
  // =========================

  Widget _buildSectionTitle(AppPalette p, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.title(p.ink)),
        const SizedBox(height: 3),
        Text(subtitle, style: AppText.caption(p.muted)),
      ],
    );
  }

  // =========================
  // HEADER
  // =========================

  Widget _buildHeader(AppPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Halo,', style: AppText.body(p.muted)),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(p.ink).copyWith(fontSize: 34),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        BrutalIconButton(
          icon: Icons.person_rounded,
          tooltip: 'Profil',
          color: p.lilac,
          onTap: openProfile,
        ),
      ],
    );
  }

  // =========================
  // KARTU HARI INI
  // =========================

  Widget _buildTodayCard(AppPalette p) {
    final now = DateTime.now();

    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

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

    final isHadir = todayStatus == 'Hadir';
    final isIzin = todayStatus == 'Izin Sakit';

    final stickerColor = isHadir
        ? p.mint
        : isIzin
        ? p.coral
        : Colors.white;

    return BrutalBox(
      color: p.lemon,
      radius: 24,
      shadow: 7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${now.day}',
                style: TextStyle(
                  color: p.onBlock,
                  fontSize: 92,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -5,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekdays[now.weekday - 1],
                        style: AppText.title(p.onBlock).copyWith(fontSize: 24),
                      ),
                      Text(
                        '${months[now.month - 1]} ${now.year}',
                        style: AppText.body(p.onBlock).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Sticker(label: todayStatus, color: stickerColor, angle: -0.05),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  todayAttendance == null
                      ? 'Kamu belum melakukan absensi.'
                      : 'Data absensi hari ini tersedia.',
                  style: AppText.caption(p.onBlock),
                ),
              ),
            ],
          ),

          if (todayAttendance != null) ...[
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildHeroTime(
                    p,
                    'Masuk',
                    formatTime(todayAttendance!.checkIn),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildHeroTime(
                    p,
                    'Pulang',
                    formatTime(todayAttendance!.checkOut),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          BrutalButton(
            label: 'Buka absensi',
            icon: Icons.fingerprint_rounded,
            color: AppColors.black,
            foreground: Colors.white,
            onPressed: openAttendance,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTime(AppPalette p, String title, String value) {
    return BrutalBox(
      radius: 12,
      shadow: 0,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.caption(AppColors.black)),
          Text(value, style: AppText.figures(AppColors.black, size: 20)),
        ],
      ),
    );
  }

  // =========================
  // STATISTICS
  // =========================

  Widget _buildStatistics(AppPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStatCard(
            p,
            title: 'Hadir',
            value: totalAttendance.toString(),
            icon: Icons.check_circle_outline,
            color: p.mint,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildStatCard(
            p,
            title: 'Pulang',
            value: totalCheckOut.toString(),
            icon: Icons.logout_rounded,
            color: p.sky,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildStatCard(
            p,
            title: 'Izin',
            value: totalIzinSakit.toString(),
            icon: Icons.event_note_rounded,
            color: p.coral,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    AppPalette p, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return BrutalBox(
      color: color,
      radius: 16,
      shadow: 4,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: p.onBlock),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppText.figures(p.onBlock, size: 36, weight: FontWeight.w900),
          ),
          Text(title, style: AppText.caption(p.onBlock)),
        ],
      ),
    );
  }

  // =========================
  // LOCATION + MAP
  // =========================

  Widget _buildLocationPanel(AppPalette p) {
    final mapPosition = currentPosition != null
        ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
        : defaultLocation;

    return BrutalBox(
      padding: EdgeInsets.zero,
      radius: 20,
      shadow: 5,
      clip: true,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: mapPosition,
                    zoom: 16,
                  ),
                  markers: currentMarker,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    mapController = controller;

                    if (currentPosition != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLng(
                          LatLng(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                          ),
                        ),
                      );
                    }
                  },
                ),

                // Label PPKD JU
                Positioned(
                  top: 12,
                  left: 12,
                  child: Sticker(
                    label: 'PPKD JU',
                    icon: Icons.location_on_rounded,
                    color: p.lemon,
                  ),
                ),

                // Tombol lokasi saya
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: BrutalIconButton(
                    icon: Icons.my_location_rounded,
                    size: 42,
                    onTap: () async {
                      await getCurrentLocation();

                      if (currentPosition != null) {
                        mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              currentPosition!.latitude,
                              currentPosition!.longitude,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const ThickDivider(),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    BlockIcon(
                      icon: Icons.location_on_rounded,
                      color: p.lilac,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lokasi saat ini', style: AppText.caption(p.muted)),
                          Text(locationAddress, style: AppText.heading(p.ink)),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    BrutalIconButton(
                      icon: Icons.refresh_rounded,
                      size: 42,
                      tooltip: 'Perbarui lokasi',
                      loading: isLocationLoading,
                      onTap: isLocationLoading ? null : getCurrentLocation,
                    ),
                  ],
                ),

                if (currentPosition != null) ...[
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: p.sky,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed_rounded, color: p.onBlock, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${currentPosition!.latitude.toStringAsFixed(6)}, '
                            '${currentPosition!.longitude.toStringAsFixed(6)}',
                            style: AppText.figures(p.onBlock, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HISTORY HEADER
  // =========================

  Widget _buildHistoryHeader(AppPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildSectionTitle(
            p,
            'Riwayat kehadiran',
            '${attendanceList.length} data absensi',
          ),
        ),

        if (attendanceList.isNotEmpty)
          TextButton(onPressed: openHistory, child: const Text('Lihat semua')),
      ],
    );
  }

  // =========================
  // HISTORY CARD
  // =========================

  String _dayOf(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);

    if (date == null) {
      return '-';
    }

    return date.day.toString().padLeft(2, '0');
  }

  String _monthShort(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return months[date.month - 1];
  }

  Widget _buildHistoryCard(AppPalette p, AttendanceModel item) {
    final isIzin = item.status.toLowerCase() == 'izin';

    final block = isIzin ? p.coral : p.mint;

    return BrutalBox(
      padding: EdgeInsets.zero,
      radius: 16,
      shadow: 4,
      clip: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 70,
              decoration: BoxDecoration(
                color: block,
                border: Border(right: BorderSide(color: p.border, width: 2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayOf(item.checkIn),
                    style: AppText.figures(
                      p.onBlock,
                      size: 30,
                      weight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _monthShort(item.checkIn),
                    style: TextStyle(
                      color: p.onBlock,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDate(item.checkIn),
                            style: AppText.heading(p.ink),
                          ),
                        ),
                        Sticker(
                          label: isIzin ? 'Izin' : 'Hadir',
                          color: block,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeItem(
                            p,
                            icon: Icons.login_rounded,
                            title: 'Masuk',
                            value: formatTime(item.checkIn),
                          ),
                        ),
                        Expanded(
                          child: _buildTimeItem(
                            p,
                            icon: Icons.logout_rounded,
                            title: 'Pulang',
                            value: formatTime(item.checkOut),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeItem(
    AppPalette p, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: p.ink),
        const SizedBox(width: 5),
        Text('$title ', style: AppText.caption(p.muted)),
        Text(value, style: AppText.figures(p.ink, size: 13)),
      ],
    );
  }

  // =========================
  // EMPTY HISTORY
  // =========================

  Widget _buildEmptyHistory(AppPalette p) {
    return BrutalBox(
      color: p.lilac,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: p.onBlock, size: 40),

          const SizedBox(height: 10),

          Text(
            'Belum ada riwayat absensi',
            style: AppText.heading(p.onBlock),
          ),

          const SizedBox(height: 4),

          Text(
            'Data absensi kamu akan muncul di sini.',
            textAlign: TextAlign.center,
            style: AppText.caption(p.onBlock),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEE ALL
  // =========================

  Widget _buildSeeAllButton(AppPalette p) {
    return BrutalButton(
      label: 'Lihat semua riwayat',
      color: p.surface,
      foreground: p.ink,
      showArrow: true,
      onPressed: openHistory,
    );
  }

  // =========================
  // DOCK NAVIGASI
  // =========================

  Widget _buildDock(AppPalette p) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _buildDockItem(
                  p,
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  active: true,
                  onTap: () {},
                ),
              ),

              VerticalDivider(width: 2, thickness: 2, color: p.border),

              Expanded(
                child: _buildDockItem(
                  p,
                  icon: Icons.fingerprint_rounded,
                  label: 'Kehadiran',
                  active: false,
                  onTap: openAttendance,
                ),
              ),

              VerticalDivider(width: 2, thickness: 2, color: p.border),

              Expanded(
                child: _buildDockItem(
                  p,
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  active: false,
                  onTap: openProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(
    AppPalette p, {
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? p.onPrimary : p.ink;

    return Material(
      color: active ? p.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
