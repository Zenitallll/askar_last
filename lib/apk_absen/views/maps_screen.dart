import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:askar_last/apk_absen/reusable/app_colors.dart';
import 'package:askar_last/apk_absen/reusable/app_widgets.dart';

class GoogleMapsScreenDay19 extends StatefulWidget {
  const GoogleMapsScreenDay19({super.key});

  @override
  State<GoogleMapsScreenDay19> createState() =>
      _GoogleMapsScreenDay19State();
}

class _GoogleMapsScreenDay19State
    extends State<GoogleMapsScreenDay19> {
  // ==============================
  // GOOGLE MAP CONTROLLER
  // ==============================

  GoogleMapController? _mapController;

  // ==============================
  // GEOCODING
  // ==============================

  final Geocoding _geocoding = Geocoding();

  // ==============================
  // LOCATION
  // ==============================

  Position? _currentPosition;

  // ==============================
  // ADDRESS
  // ==============================

  String _currentAddress = 'Mencari lokasi...';

  // ==============================
  // MARKER
  // ==============================

  final Set<Marker> _markers = {};

  // ==============================
  // DEFAULT LOCATION
  // Jakarta
  // ==============================

  static const LatLng _defaultLocation = LatLng(
    -6.200000,
    106.816666,
  );

  // ==============================
  // LOADING
  // ==============================

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _checkPermissionsAndGetLocation();
  }

  // ============================================================
  // CEK GPS DAN PERMISSION
  // ============================================================

  Future<void> _checkPermissionsAndGetLocation() async {
    try {
      // Cek apakah GPS aktif
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _currentAddress =
              'GPS sedang tidak aktif.';
        });

        return;
      }

      // Cek permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      // Kalau permission belum diberikan
      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _currentAddress =
                'Izin lokasi ditolak.';
          });

          return;
        }
      }

      // Kalau permission ditolak permanen
      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _currentAddress =
              'Izin lokasi ditolak permanen.';
        });

        return;
      }

      // Kalau semua aman
      await _getCurrentLocation();
    } catch (e) {
      log(
        'Permission/location error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentAddress =
            'Gagal mendapatkan lokasi.';
      });
    }
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    try {
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      log(
        'Latitude: ${position.latitude}',
      );

      log(
        'Longitude: ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Update marker
      _updateMarker(position);

      // Geser kamera
      _moveCameraToLocation(position);

      // Ambil alamat
      await _getAddressFromLatLng(position);
    } catch (e) {
      log(
        'Error getting current location: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _currentAddress =
            'Gagal mengambil lokasi.';
      });
    }
  }

  // ============================================================
  // UPDATE MARKER
  // ============================================================

  void _updateMarker(Position position) {
    final LatLng currentLatLng = LatLng(
      position.latitude,
      position.longitude,
    );

    setState(() {
      _markers.clear();

      _markers.add(
        Marker(
          markerId:
              const MarkerId('currentLocation'),
          position: currentLatLng,
          infoWindow: const InfoWindow(
            title: 'Lokasi Anda',
            snippet:
                'Posisi kamu saat ini',
          ),
        ),
      );
    });
  }

  // ============================================================
  // MOVE CAMERA
  // ============================================================

  void _moveCameraToLocation(
      Position position) {
    if (_mapController == null) {
      return;
    }

    final LatLng currentLatLng = LatLng(
      position.latitude,
      position.longitude,
    );

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLatLng,
          zoom: 16,
        ),
      ),
    );
  }

  // ============================================================
  // GET ADDRESS FROM LATITUDE LONGITUDE
  // ============================================================

  Future<void> _getAddressFromLatLng(
      Position position) async {
    try {
      // Untuk geocoding 5.0.0
      // harus menggunakan instance Geocoding.
      final List<Placemark> placemarks =
          await _geocoding
              .placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        if (!mounted) return;

        setState(() {
          _currentAddress =
              'Alamat tidak ditemukan.';
        });

        return;
      }

      final Placemark place =
          placemarks.first;

      log(
        'Placemark: ${place.toString()}',
      );

      if (!mounted) return;

      setState(() {
        _currentAddress =
            _buildAddress(place);
      });
    } catch (e) {
      log(
        'Error reverse geocoding: $e',
      );

      if (!mounted) return;

      setState(() {
        _currentAddress =
            'Alamat tidak dapat ditemukan.';
      });
    }
  }

  // ============================================================
  // BUILD ADDRESS TEXT
  // ============================================================

  String _buildAddress(
      Placemark place) {
    final List<String> parts = [];

    if (place.street != null &&
        place.street!.isNotEmpty) {
      parts.add(place.street!);
    }

    if (place.subLocality != null &&
        place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    if (place.locality != null &&
        place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    if (place.postalCode != null &&
        place.postalCode!.isNotEmpty) {
      parts.add(place.postalCode!);
    }

    if (place.country != null &&
        place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    if (parts.isEmpty) {
      return 'Alamat tidak ditemukan.';
    }

    return parts.join(', ');
  }

  // ============================================================
  // OPEN GOOGLE MAPS
  // ============================================================

  Future<void> _openInGoogleMaps() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi belum tersedia.',
          ),
        ),
      );

      return;
    }

    final double latitude =
        _currentPosition!.latitude;

    final double longitude =
        _currentPosition!.longitude;

    log(
      'Google Maps: $latitude,$longitude',
    );

    // Kalau nanti mau benar-benar membuka
    // aplikasi Google Maps eksternal,
    // bisa ditambahkan url_launcher.
    //
    // Untuk sekarang tombol ini hanya
    // memastikan lokasi sudah tersedia.

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Lokasi: $latitude, $longitude',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: const Text(
          'Peta lokasi',
        ),
      ),

      body: Stack(
        children: [

          // ======================================================
          // GOOGLE MAP
          // ======================================================

          GoogleMap(
            initialCameraPosition:
                const CameraPosition(
              target: _defaultLocation,
              zoom: 13,
            ),

            // Marker lokasi user
            markers: _markers,

            // Titik lokasi bawaan Google Maps
            myLocationEnabled: true,

            // Tombol current location
            myLocationButtonEnabled: true,

            // Zoom control
            zoomControlsEnabled: false,

            // Kompas
            compassEnabled: true,

            // Toolbar Google Maps
            mapToolbarEnabled: true,

            // Callback ketika map sudah dibuat
            onMapCreated:
                (GoogleMapController controller) {
              _mapController = controller;

              // Kalau lokasi sudah tersedia
              // langsung arahkan kamera
              if (_currentPosition != null) {
                _moveCameraToLocation(
                  _currentPosition!,
                );
              }
            },
          ),

          // ======================================================
          // LOADING
          // ======================================================

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // ======================================================
          // ADDRESS CARD
          // ======================================================

          Positioned(
            bottom: 24,
            left: 16,
            right: 20,

            child: BrutalBox(
              radius: 20,
              shadow: 6,
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // ==============================================
                  // ADDRESS ROW
                  // ==============================================

                  Row(
                    children: [

                      BlockIcon(
                        icon:
                            Icons.location_on_rounded,
                        color: p.lemon,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(
                              'Alamat kamu saat ini',
                              style:
                                  AppText.caption(
                                p.muted,
                              ),
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              _currentAddress,
                              maxLines: 3,
                              overflow:
                                  TextOverflow
                                      .ellipsis,

                              style:
                                  AppText.body(
                                p.ink,
                              ).copyWith(
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      // ==========================================
                      // LOCATION BUTTON
                      // ==========================================

                      BrutalIconButton(
                        icon:
                            Icons.my_location,
                        size: 42,
                        tooltip:
                            'Perbarui lokasi',
                        color: p.sky,

                        onTap:
                            _checkPermissionsAndGetLocation,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==============================================
                  // GOOGLE MAPS BUTTON
                  // ==============================================

                  BrutalButton(
                    label:
                        'Buka di Google Maps',

                    icon:
                        Icons.navigation_rounded,

                    onPressed:
                        _openInGoogleMaps,
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