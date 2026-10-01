class Patient {
  int? id;

  String name;
  String age;
  String phone;
  String queue;

  // Doctor relationship
  int? doctorId;
  String? doctorName;
  String? specialty;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.phone,
    required this.queue,
    this.doctorId,
    this.doctorName,
    this.specialty,
  });

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "age": age,
      "phone": phone,
      "queue": queue,
      "doctor_id": doctorId,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory Patient.fromMap(Map<String, dynamic> map) {
    String? doctorName;
    String? specialty;

    // If doctor information comes from Supabase relationship
    if (map["doctors"] != null) {
      final doctor = map["doctors"];

      if (doctor is Map<String, dynamic>) {
        doctorName = doctor["name"]?.toString();
        specialty = doctor["specialty"]?.toString();
      }
    }

    return Patient(
      id: map["id"],
      name: map["name"]?.toString() ?? "",
      age: map["age"]?.toString() ?? "",
      phone: map["phone"]?.toString() ?? "",
      queue: map["queue"]?.toString() ?? "",
      doctorId: map["doctor_id"],
      doctorName: doctorName,
      specialty: specialty,
    );
  }
}
