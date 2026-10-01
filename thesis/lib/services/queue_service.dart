import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';
import '../models/queue_patient.dart';

class QueueService {
  static final SupabaseClient supabase = Supabase.instance.client;

  static const Duration timeoutDuration = Duration(seconds: 15);

  // ============================================================
  // GET ALL QUEUE PATIENTS
  // ============================================================

  static Future<List<QueuePatient>> getQueue() async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .order('id', ascending: true)
          .timeout(timeoutDuration);

      return data.map<QueuePatient>((e) {
        return QueuePatient.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      throw Exception('Failed to load queue: $e');
    }
  }

  // ============================================================
  // GET NEXT QUEUE NUMBER
  // ============================================================

  static Future<String> getNextQueueNumber({int? doctorId}) async {
    try {
      var query = supabase.from('queue').select('number, doctor_id');

      if (doctorId != null) {
        query = query.eq('doctor_id', doctorId);
      } else {
        query = query.isFilter('doctor_id', null);
      }

      final data = await query.timeout(timeoutDuration);

      int highestNumber = 0;

      for (final item in data) {
        final value = item['number']?.toString() ?? '';

        final match = RegExp(r'\d+').firstMatch(value);

        if (match != null) {
          final number = int.tryParse(match.group(0)!) ?? 0;

          if (number > highestNumber) {
            highestNumber = number;
          }
        }
      }

      final nextNumber = highestNumber + 1;

      return 'Q${nextNumber.toString().padLeft(3, '0')}';
    } catch (e) {
      throw Exception('Failed to generate queue number: $e');
    }
  }

  // ============================================================
  // ADD NEW PATIENT DIRECTLY TO QUEUE
  // ============================================================

  static Future<QueuePatient> addPatientAuto(
    String name, {
    int? doctorId,
  }) async {
    try {
      final queueNumber = await getNextQueueNumber(doctorId: doctorId);

      final response = await supabase
          .from('queue')
          .insert({
            'number': queueNumber,
            'name': name,
            'status': 'Waiting',
            'doctor_id': doctorId,
          })
          .select('*, doctors(id, name, specialty)')
          .single()
          .timeout(timeoutDuration);

      return QueuePatient.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Failed to add patient to queue: $e');
    }
  }

  // ============================================================
  // ADD EXISTING PATIENT TO QUEUE
  // ============================================================

  static Future<QueuePatient> addExistingPatientToQueue(Patient patient) async {
    try {
      final queueNumber = await getNextQueueNumber(doctorId: patient.doctorId);

      final response = await supabase
          .from('queue')
          .insert({
            'number': queueNumber,
            'name': patient.name,
            'status': 'Waiting',
            'doctor_id': patient.doctorId,
          })
          .select('*, doctors(id, name, specialty)')
          .single()
          .timeout(timeoutDuration);

      return QueuePatient.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Failed to add existing patient to queue: $e');
    }
  }

  // ============================================================
  // ADD QUEUE PATIENT
  // ============================================================

  static Future<void> addPatient(QueuePatient patient) async {
    try {
      await supabase
          .from('queue')
          .insert({
            'number': patient.number,
            'name': patient.name,
            'status': patient.status,
            'doctor_id': patient.doctorId,
          })
          .timeout(timeoutDuration);
    } catch (e) {
      throw Exception('Failed to add queue patient: $e');
    }
  }

  // ============================================================
  // SAVE COMPLETED PATIENT TO HISTORY
  // ============================================================

  static Future<void> _saveToHistory(Map<String, dynamic> patient) async {
    final now = DateTime.now();

    final doctor = patient['doctors'] is Map
        ? Map<String, dynamic>.from(patient['doctors'])
        : null;

    final patientName = patient['name']?.toString() ?? 'Unknown Patient';

    final queueNumber = patient['number']?.toString() ?? '';

    final doctorId = patient['doctor_id'];

    final doctorName = doctor?['name']?.toString() ?? 'Unknown Doctor';

    final historyDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    await supabase.from('queue_history').insert({
      'patient_name': patientName,
      'number': queueNumber,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'history_date': historyDate,
      'created_at': now.toIso8601String(),
      'completed_count': 1,
    });
  }

  // ============================================================
  // COMPLETE PATIENT
  // ============================================================

  static Future<void> _completePatient(Map<String, dynamic> patient) async {
    final patientId = patient['id'];

    if (patientId == null) {
      throw Exception('Patient ID is missing');
    }

    final currentStatus = patient['status']?.toString() ?? '';

    // ----------------------------------------------------------
    // ALREADY COMPLETED
    // ----------------------------------------------------------

    if (currentStatus == 'Completed') {
      return;
    }

    // ----------------------------------------------------------
    // SAVE TO HISTORY
    // ----------------------------------------------------------

    await _saveToHistory(patient);

    // ----------------------------------------------------------
    // UPDATE QUEUE
    // ----------------------------------------------------------

    await supabase
        .from('queue')
        .update({
          'status': 'Completed',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', patientId)
        .timeout(timeoutDuration);
  }

  // ============================================================
  // UPDATE QUEUE PATIENT
  // ============================================================

  static Future<void> updatePatient(QueuePatient patient) async {
    if (patient.id == null) {
      throw Exception('Patient ID is missing');
    }

    try {
      // --------------------------------------------------------
      // COMPLETED
      // --------------------------------------------------------

      if (patient.status == 'Completed') {
        final existing = await supabase
            .from('queue')
            .select('*, doctors(id, name, specialty)')
            .eq('id', patient.id!)
            .single()
            .timeout(timeoutDuration);

        await _completePatient(Map<String, dynamic>.from(existing));

        return;
      }

      // --------------------------------------------------------
      // NORMAL UPDATE
      // --------------------------------------------------------

      await supabase
          .from('queue')
          .update({
            'number': patient.number,
            'name': patient.name,
            'status': patient.status,
            'doctor_id': patient.doctorId,
          })
          .eq('id', patient.id!)
          .timeout(timeoutDuration);
    } catch (e) {
      throw Exception('Failed to update queue patient: $e');
    }
  }

  // ============================================================
  // GET COMPLETED PATIENTS TODAY
  // ============================================================

  static Future<int> getCompletedTodayCount() async {
    try {
      final now = DateTime.now();

      final historyDate =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';

      final data = await supabase
          .from('queue_history')
          .select('completed_count')
          .eq('history_date', historyDate)
          .timeout(timeoutDuration);

      int totalCompleted = 0;

      for (final item in data) {
        final value = item['completed_count'];

        if (value is int) {
          totalCompleted += value;
        } else {
          totalCompleted += int.tryParse(value?.toString() ?? '0') ?? 0;
        }
      }

      return totalCompleted;
    } catch (e) {
      throw Exception('Failed to load completed patients today: $e');
    }
  }

  // ============================================================
  // SERVE NEXT PATIENT - GLOBAL
  // ============================================================

  static Future<QueuePatient?> serveNextPatient() async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Waiting')
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      if (data.isEmpty) {
        return null;
      }

      final patient = QueuePatient.fromMap(
        Map<String, dynamic>.from(data.first),
      );

      if (patient.id == null) {
        throw Exception('Patient ID is missing');
      }

      await supabase
          .from('queue')
          .update({'status': 'Current'})
          .eq('id', patient.id!)
          .timeout(timeoutDuration);

      patient.status = 'Current';

      return patient;
    } catch (e) {
      throw Exception('Failed to serve next patient: $e');
    }
  }

  // ============================================================
  // SERVE NEXT PATIENT FOR SPECIFIC DOCTOR
  // ============================================================

  static Future<QueuePatient?> serveNextPatientForDoctor(int doctorId) async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Waiting')
          .eq('doctor_id', doctorId)
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      if (data.isEmpty) {
        return null;
      }

      final patient = QueuePatient.fromMap(
        Map<String, dynamic>.from(data.first),
      );

      if (patient.id == null) {
        throw Exception('Patient ID is missing');
      }

      await supabase
          .from('queue')
          .update({'status': 'Current'})
          .eq('id', patient.id!)
          .timeout(timeoutDuration);

      patient.status = 'Current';

      return patient;
    } catch (e) {
      throw Exception('Failed to serve next patient for doctor: $e');
    }
  }

  // ============================================================
  // COMPLETE CURRENT + SERVE NEXT - GLOBAL
  // ============================================================

  static Future<QueuePatient?> completeCurrentAndServeNext() async {
    try {
      // --------------------------------------------------------
      // FIND CURRENT PATIENT
      // --------------------------------------------------------

      final currentData = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Current')
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      // --------------------------------------------------------
      // COMPLETE CURRENT
      // --------------------------------------------------------

      if (currentData.isNotEmpty) {
        final currentPatient = Map<String, dynamic>.from(currentData.first);

        await _completePatient(currentPatient);
      }

      // --------------------------------------------------------
      // FIND NEXT WAITING
      // --------------------------------------------------------

      final waitingData = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Waiting')
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      if (waitingData.isEmpty) {
        return null;
      }

      final nextPatient = QueuePatient.fromMap(
        Map<String, dynamic>.from(waitingData.first),
      );

      if (nextPatient.id == null) {
        throw Exception('Next patient ID is missing');
      }

      await supabase
          .from('queue')
          .update({'status': 'Current'})
          .eq('id', nextPatient.id!)
          .timeout(timeoutDuration);

      nextPatient.status = 'Current';

      return nextPatient;
    } catch (e) {
      throw Exception('Failed to complete current patient: $e');
    }
  }

  // ============================================================
  // COMPLETE CURRENT + SERVE NEXT FOR DOCTOR
  // ============================================================

  static Future<QueuePatient?> completeCurrentAndServeNextForDoctor(
    int doctorId,
  ) async {
    try {
      // --------------------------------------------------------
      // FIND CURRENT FOR DOCTOR
      // --------------------------------------------------------

      final currentData = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Current')
          .eq('doctor_id', doctorId)
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      // --------------------------------------------------------
      // COMPLETE CURRENT
      // --------------------------------------------------------

      if (currentData.isNotEmpty) {
        final currentPatient = Map<String, dynamic>.from(currentData.first);

        await _completePatient(currentPatient);
      }

      // --------------------------------------------------------
      // FIND NEXT WAITING FOR SAME DOCTOR
      // --------------------------------------------------------

      final waitingData = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Waiting')
          .eq('doctor_id', doctorId)
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      if (waitingData.isEmpty) {
        return null;
      }

      final nextPatient = QueuePatient.fromMap(
        Map<String, dynamic>.from(waitingData.first),
      );

      if (nextPatient.id == null) {
        throw Exception('Next patient ID is missing');
      }

      await supabase
          .from('queue')
          .update({'status': 'Current'})
          .eq('id', nextPatient.id!)
          .timeout(timeoutDuration);

      nextPatient.status = 'Current';

      return nextPatient;
    } catch (e) {
      throw Exception('Failed to complete doctor queue: $e');
    }
  }

  // ============================================================
  // GET QUEUE FOR SPECIFIC DOCTOR
  // ============================================================

  static Future<List<QueuePatient>> getQueueForDoctor(int doctorId) async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('doctor_id', doctorId)
          .order('id', ascending: true)
          .timeout(timeoutDuration);

      return data.map<QueuePatient>((e) {
        return QueuePatient.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      throw Exception('Failed to load doctor queue: $e');
    }
  }

  // ============================================================
  // GET WAITING PATIENTS FOR DOCTOR
  // ============================================================

  static Future<List<QueuePatient>> getWaitingPatientsForDoctor(
    int doctorId,
  ) async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('doctor_id', doctorId)
          .eq('status', 'Waiting')
          .order('id', ascending: true)
          .timeout(timeoutDuration);

      return data.map<QueuePatient>((e) {
        return QueuePatient.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      throw Exception('Failed to load waiting patients: $e');
    }
  }

  // ============================================================
  // GET CURRENT PATIENT FOR DOCTOR
  // ============================================================

  static Future<QueuePatient?> getCurrentPatientForDoctor(int doctorId) async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('doctor_id', doctorId)
          .eq('status', 'Current')
          .order('id', ascending: true)
          .limit(1)
          .timeout(timeoutDuration);

      if (data.isEmpty) {
        return null;
      }

      return QueuePatient.fromMap(Map<String, dynamic>.from(data.first));
    } catch (e) {
      throw Exception('Failed to load current patient: $e');
    }
  }

  // ============================================================
  // GET CURRENT PATIENTS - ALL DOCTORS
  // ============================================================

  static Future<List<QueuePatient>> getCurrentPatients() async {
    try {
      final data = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .eq('status', 'Current')
          .order('id', ascending: true)
          .timeout(timeoutDuration);

      return data.map<QueuePatient>((e) {
        return QueuePatient.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    } catch (e) {
      throw Exception('Failed to load current patients: $e');
    }
  }

  // ============================================================
  // DELETE PATIENT FROM QUEUE
  // ============================================================

  static Future<void> deletePatient(int id) async {
    try {
      await supabase
          .from('queue')
          .delete()
          .eq('id', id)
          .timeout(timeoutDuration);
    } catch (e) {
      throw Exception('Failed to delete queue patient: $e');
    }
  }
}
