class Doctor {
  int? id;

  String name;
  String specialty;

  String? shift1Start;
  String? shift1End;

  String? shift2Start;
  String? shift2End;

  bool isActive;

  Doctor({
    this.id,
    required this.name,
    required this.specialty,
    this.shift1Start,
    this.shift1End,
    this.shift2Start,
    this.shift2End,
    this.isActive = true,
  });

  // ============================================================
  // CONVERT DOCTOR TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'shift1_start': shift1Start,
      'shift1_end': shift1End,
      'shift2_start': shift2Start,
      'shift2_end': shift2End,
      'is_active': isActive,
    };
  }

  // ============================================================
  // CREATE DOCTOR FROM SUPABASE
  // ============================================================

  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      name: map['name']?.toString() ?? '',
      specialty: map['specialty']?.toString() ?? '',
      shift1Start: map['shift1_start']?.toString(),
      shift1End: map['shift1_end']?.toString(),
      shift2Start: map['shift2_start']?.toString(),
      shift2End: map['shift2_end']?.toString(),
      isActive: map['is_active'] ?? true,
    );
  }
}
