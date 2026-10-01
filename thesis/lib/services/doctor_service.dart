import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/doctor.dart';

class DoctorService {
  static final supabase = Supabase.instance.client;

  // ============================================================
  // GET ALL DOCTORS
  // ============================================================

  static Future<List<Doctor>> getDoctors() async {
    final data = await supabase
        .from('doctors')
        .select()
        .order('id', ascending: true);

    return data.map<Doctor>((e) => Doctor.fromMap(e)).toList();
  }

  // ============================================================
  // GET ACTIVE DOCTORS
  // ============================================================

  static Future<List<Doctor>> getActiveDoctors() async {
    final data = await supabase
        .from('doctors')
        .select()
        .eq('is_active', true)
        .order('id', ascending: true);

    return data.map<Doctor>((e) => Doctor.fromMap(e)).toList();
  }

  // ============================================================
  // ADD DOCTOR
  // ============================================================

  static Future<Doctor> addDoctor(Doctor doctor) async {
    final response = await supabase
        .from('doctors')
        .insert(doctor.toMap())
        .select()
        .single();

    return Doctor.fromMap(response);
  }

  // ============================================================
  // UPDATE DOCTOR
  // ============================================================

  static Future<void> updateDoctor(Doctor doctor) async {
    if (doctor.id == null) {
      throw Exception("Doctor ID is missing");
    }

    await supabase.from('doctors').update(doctor.toMap()).eq('id', doctor.id!);
  }

  // ============================================================
  // DELETE DOCTOR
  // ============================================================

  static Future<void> deleteDoctor(int id) async {
    await supabase.from('doctors').delete().eq('id', id);
  }

  // ============================================================
  // CHANGE ACTIVE / INACTIVE
  // ============================================================

  static Future<void> setDoctorActive(int id, bool isActive) async {
    await supabase.from('doctors').update({'is_active': isActive}).eq('id', id);
  }
}
