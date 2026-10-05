class AttendanceModel {
  final int id;
  final int userId;
  final String? checkIn;
  final String? checkInLocation;
  final String? checkInAddress;
  final String? checkOut;
  final String? checkOutLocation;
  final String? checkOutAddress;
  final String status;
  final String? alasanIzin;
  final String? createdAt;
  final String? updatedAt;

  AttendanceModel({
    required this.id,
    required this.userId,
    this.checkIn,
    this.checkInLocation,
    this.checkInAddress,
    this.checkOut,
    this.checkOutLocation,
    this.checkOutAddress,
    required this.status,
    this.alasanIzin,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      userId: json['user_id'],
      checkIn: json['check_in'],
      checkInLocation: json['check_in_location'],
      checkInAddress: json['check_in_address'],
      checkOut: json['check_out'],
      checkOutLocation: json['check_out_location'],
      checkOutAddress: json['check_out_address'],
      status: json['status'],
      alasanIzin: json['alasan_izin'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
