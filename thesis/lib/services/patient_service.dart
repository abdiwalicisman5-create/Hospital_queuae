import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';
import 'queue_service.dart';

class PatientService {
  static final SupabaseClient supabase = Supabase.instance.client;

  static const Duration timeoutDuration = Duration(seconds: 15);

  // ============================================================
  // GET ALL PATIENTS
  // ============================================================

  static Future<List<Patient>> getPatients() async {
    try {
      final data = await supabase
          .from('patients')
          .select('*, doctors(id, name, specialty)')
          .order('id', ascending: true)
          .timeout(timeoutDuration);

      return data.map<Patient>((e) {
        return Patient.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      throw Exception('Failed to load patients: $e');
    }
  }

  // ============================================================
  // GET ACTIVE DOCTORS
  // ============================================================

  static Future<List<Map<String, dynamic>>> getDoctors() async {
    try {
      final data = await supabase
          .from('doctors')
          .select('id, name, specialty')
          .eq('is_active', true)
          .order('name', ascending: true)
          .timeout(timeoutDuration);

      return List<Map<String, dynamic>>.from(
        data.map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (e) {
      throw Exception('Failed to load doctors: $e');
    }
  }

  // ============================================================
  // ADD PATIENT
  //
  // IMPORTANT:
  // When a new patient is registered:
  //
  // 1. Patient is saved in patients table.
  // 2. Patient is automatically added to queue.
  // 3. Selected doctor is copied to queue.
  // 4. Queue number is generated automatically.
  //
  // Example:
  //
  // Salmo Muuse
  // Doctor: Dr. Ahmed
  //
  // ↓
  //
  // patients table
  // ↓
  // queue table
  // ↓
  // Q001
  // Waiting
  // Dr. Ahmed
  // ============================================================

  static Future<void> addPatient(Patient patient) async {
    try {
      // ----------------------------------------------------------
      // STEP 1: SAVE PATIENT
      // ----------------------------------------------------------

      await supabase
          .from('patients')
          .insert({
            'name': patient.name,
            'age': patient.age,
            'phone': patient.phone,
            'queue': patient.queue,
            'doctor_id': patient.doctorId,
          })
          .timeout(timeoutDuration);

      // ----------------------------------------------------------
      // STEP 2: AUTOMATICALLY ADD TO QUEUE
      // ----------------------------------------------------------

      await QueueService.addExistingPatientToQueue(patient);
    } catch (e) {
      throw Exception('Failed to register patient and add to queue: $e');
    }
  }

  // ============================================================
  // UPDATE PATIENT
  // ============================================================

  static Future<void> updatePatient(Patient patient) async {
    if (patient.id == null) {
      throw Exception('Patient ID is required for update.');
    }

    try {
      await supabase
          .from('patients')
          .update({
            'name': patient.name,
            'age': patient.age,
            'phone': patient.phone,
            'queue': patient.queue,
            'doctor_id': patient.doctorId,
          })
          .eq('id', patient.id!)
          .timeout(timeoutDuration);
    } catch (e) {
      throw Exception('Failed to update patient: $e');
    }
  }

  // ============================================================
  // DELETE PATIENT
  // ============================================================

  static Future<void> deletePatient(int id) async {
    try {
      await supabase
          .from('patients')
          .delete()
          .eq('id', id)
          .timeout(timeoutDuration);
    } catch (e) {
      throw Exception('Failed to delete patient: $e');
    }
  }
}
