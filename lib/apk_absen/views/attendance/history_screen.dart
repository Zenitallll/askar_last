import 'package:flutter/material.dart';

import '../../models/attendance_model.dart';
import '../../services/api_services.dart';
import '../../services/storage_services.dart';
import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/app_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  List<AttendanceModel> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getHistory();
  }

  Future<void> getHistory() async {
    try {
      final token = await StorageServices.getToken();

      if (token == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final response = await ApiServices().getHistory(
        token: token,
        start: '2026-01-01',
        end: '2026-12-31',
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'];

        if (!mounted) return;

        setState(() {
          history = data.map((item) => AttendanceModel.fromJson(item)).toList();

          isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengambil riwayat: $e')));
    }
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(value);

      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MEI',
        'JUN',
        'JUL',
        'AGU',
        'SEP',
        'OKT',
        'NOV',
        'DES',
      ];

      return '${dateTime.day.toString().padLeft(2, '0')} '
          '${months[dateTime.month - 1]} '
          '${dateTime.year}';
    } catch (_) {
      return value;
    }
  }

  String formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(value);

      return '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}:'
          '${dateTime.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  bool isPermission(String status) {
    return status.toLowerCase() == 'izin';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      appBar: buildAppBar(
        context,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat absensi', style: AppText.title(p.ink)),
            Text('Aktivitas absensi kamu', style: AppText.caption(p.muted)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: BrutalIconButton(
              icon: Icons.refresh_rounded,
              size: 40,
              tooltip: 'Muat ulang',
              color: p.lemon,
              onTap: getHistory,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: p.primary))
          : history.isEmpty
          ? _buildEmptyState(p)
          : RefreshIndicator(
              color: p.onPrimary,
              backgroundColor: p.primary,
              onRefresh: getHistory,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(p, history[index]);
                },
              ),
            ),
    );
  }

  Widget _buildHistoryCard(AppPalette p, AttendanceModel item) {
    final izin = isPermission(item.status);

    final block = izin ? p.coral : p.mint;

    final hasCheckOut = item.checkOut != null && item.checkOut!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: BrutalBox(
        padding: EdgeInsets.zero,
        radius: 18,
        shadow: 5,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kepala kartu berwarna: tanggal, jam, status
            Container(
              color: block,
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(item.checkIn ?? item.createdAt),
                          style: AppText.title(p.onBlock).copyWith(fontSize: 19),
                        ),
                        Text(
                          formatTime(item.checkIn ?? item.createdAt),
                          style: AppText.figures(p.onBlock, size: 12),
                        ),
                      ],
                    ),
                  ),

                  _statusBadge(item.status, p.surface, p.ink),

                  IconButton(
                    onPressed: () {
                      _showDeleteDialog(item);
                    },
                    tooltip: 'Hapus',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: p.onBlock,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const ThickDivider(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTimeline(
                    p,
                    icon: Icons.login_rounded,
                    title: 'Check In',
                    time: formatTime(item.checkIn),
                    location:
                        item.checkInAddress ?? item.checkInLocation ?? '-',
                  ),

                  if (hasCheckOut) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 2,
                        thickness: 1.5,
                        color: p.border.withValues(alpha: 0.25),
                      ),
                    ),

                    _buildTimeline(
                      p,
                      icon: Icons.logout_rounded,
                      title: 'Check Out',
                      time: formatTime(item.checkOut),
                      location:
                          item.checkOutAddress ?? item.checkOutLocation ?? '-',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(
    AppPalette p, {
    required IconData icon,
    required String title,
    required String time,
    required String location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.lilac,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border, width: 2),
          ),
          child: Text(time, style: AppText.figures(p.onBlock, size: 13)),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: p.ink),
                  const SizedBox(width: 6),
                  Text(title, style: AppText.heading(p.ink)),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, color: p.muted, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: AppText.caption(p.muted).copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status, Color color, Color textColor) {
    final label = status.isEmpty
        ? '-'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Sticker(label: label, color: color, textColor: textColor);
  }

  Widget _buildEmptyState(AppPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrutalBox(
              expand: false,
              color: p.lilac,
              radius: 28,
              shadow: 6,
              padding: const EdgeInsets.all(24),
              child: Icon(Icons.inbox_rounded, color: p.onBlock, size: 52),
            ),
            const SizedBox(height: 26),
            Text('Belum ada riwayat', style: AppText.display(p.ink).copyWith(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              'Riwayat absensi kamu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: AppText.body(p.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(AttendanceModel item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final p = AppColors.of(dialogContext);

        return buildAppDialog(
          dialogContext,
          title: 'Hapus riwayat?',
          message:
              'Apakah kamu yakin ingin menghapus '
              'riwayat absensi ini?',
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
              label: 'Hapus',
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

    if (result == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fitur hapus siap dihubungkan ke API DELETE.'),
        ),
      );
    }
  }
}
