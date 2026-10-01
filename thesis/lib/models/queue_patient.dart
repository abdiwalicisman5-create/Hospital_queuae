class QueuePatient {
  int? id;

  String number;
  String name;
  String status;

  // Doctor relationship
  int? doctorId;
  String? doctorName;
  String? specialty;

  // Queue timestamps
  DateTime? createdAt;
  DateTime? completedAt;

  QueuePatient({
    this.id,
    required this.number,
    required this.name,
    required this.status,
    this.doctorId,
    this.doctorName,
    this.specialty,
    this.createdAt,
    this.completedAt,
  });

  // ============================================================
  // FLUTTER → SUPABASE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      "number": number,
      "name": name,
      "status": status,
      "doctor_id": doctorId,
      "created_at": createdAt?.toIso8601String(),
      "completed_at": completedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // SUPABASE → FLUTTER
  // ============================================================

  factory QueuePatient.fromMap(Map<String, dynamic> map) {
    String? doctorName;
    String? specialty;

    if (map["doctors"] != null) {
      final doctor = map["doctors"];

      if (doctor is Map<String, dynamic>) {
        doctorName = doctor["name"]?.toString();
        specialty = doctor["specialty"]?.toString();
      }
    }

    DateTime? createdAt;
    DateTime? completedAt;

    if (map["created_at"] != null) {
      createdAt = DateTime.tryParse(map["created_at"].toString());
    }

    if (map["completed_at"] != null) {
      completedAt = DateTime.tryParse(map["completed_at"].toString());
    }

    return QueuePatient(
      id: map["id"] is int
          ? map["id"]
          : int.tryParse(map["id"]?.toString() ?? ""),
      number: map["number"]?.toString() ?? "",
      name: map["name"]?.toString() ?? "",
      status: map["status"]?.toString() ?? "Waiting",

      doctorId: map["doctor_id"] is int
          ? map["doctor_id"]
          : int.tryParse(map["doctor_id"]?.toString() ?? ""),

      doctorName: doctorName,
      specialty: specialty,

      createdAt: createdAt,
      completedAt: completedAt,
    );
  }
}
