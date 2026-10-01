import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/queue_patient.dart';
import '../models/patient.dart';
import '../services/queue_service.dart';
import '../services/patient_service.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<QueuePatient> patients = [];
  List<Map<String, dynamic>> doctors = [];

  int? selectedDoctorId;

  bool isLoading = true;
  bool isProcessing = false;

  RealtimeChannel? _queueChannel;

  @override
  void initState() {
    super.initState();

    loadData();
    setupRealtime();
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void setupRealtime() {
    _queueChannel = Supabase.instance.client
        .channel('queue-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'queue',
          callback: (payload) {
            loadQueue();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_queueChannel != null) {
      Supabase.instance.client.removeChannel(_queueChannel!);
    }

    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final queueData = await QueueService.getQueue();
      final doctorData = await PatientService.getDoctors();

      if (!mounted) return;

      setState(() {
        patients = queueData;
        doctors = doctorData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading queue: $e")));
    }
  }

  Future<void> loadQueue() async {
    try {
      final result = await QueueService.getQueue();

      if (!mounted) return;

      setState(() {
        patients = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading queue: $e")));
    }
  }

  // ============================================================
  // FILTERED QUEUE
  // ============================================================

  List<QueuePatient> get filteredPatients {
    if (selectedDoctorId == null) {
      return patients;
    }

    return patients.where((patient) {
      return patient.doctorId == selectedDoctorId;
    }).toList();
  }

  // ============================================================
  // CURRENT PATIENT
  // ============================================================

  QueuePatient? get currentPatient {
    for (final patient in filteredPatients) {
      if (patient.status == "Current") {
        return patient;
      }
    }

    return null;
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get waitingCount {
    return filteredPatients
        .where((patient) => patient.status == "Waiting")
        .length;
  }

  int get completedCount {
    return filteredPatients
        .where((patient) => patient.status == "Completed")
        .length;
  }

  // ============================================================
  // SELECTED DOCTOR NAME
  // ============================================================

  String get selectedDoctorName {
    if (selectedDoctorId == null) {
      return "All Doctors";
    }

    for (final doctor in doctors) {
      final id = doctor["id"] is int
          ? doctor["id"]
          : int.tryParse(doctor["id"]?.toString() ?? "");

      if (id == selectedDoctorId) {
        return doctor["name"]?.toString() ?? "Doctor";
      }
    }

    return "Doctor";
  }

  // ============================================================
  // ADD EXISTING PATIENT TO QUEUE
  // ============================================================

  Future<void> showAddToQueueDialog() async {
    try {
      final List<Patient> patientList = await PatientService.getPatients();

      if (!mounted) return;

      if (patientList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No registered patients. Please register a patient first.",
            ),
          ),
        );

        return;
      }

      Patient? selectedPatient;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text(
                  "Add Patient to Queue",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                content: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // PATIENT
                      // ==================================================
                      DropdownButtonFormField<Patient>(
                        initialValue: selectedPatient,

                        decoration: const InputDecoration(
                          labelText: "Select Patient",
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),

                        items: patientList.map((patient) {
                          final doctorText =
                              patient.doctorName == null ||
                                  patient.doctorName!.isEmpty
                              ? "No doctor"
                              : patient.doctorName!;

                          return DropdownMenuItem<Patient>(
                            value: patient,
                            child: Text("${patient.name} - $doctorText"),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setDialogState(() {
                            selectedPatient = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // SELECTED DOCTOR
                      // ==================================================
                      if (selectedDoctorId != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.medical_services,
                                color: Colors.blue,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  "Queue Doctor: "
                                  "$selectedDoctorName",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (selectedDoctorId == null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),

                              SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  "All Doctors selected. "
                                  "The patient's assigned doctor "
                                  "will be used.",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text("Cancel"),
                  ),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.queue),
                    label: const Text("Add to Queue"),

                    onPressed: selectedPatient == null
                        ? null
                        : () async {
                            try {
                              final patient = selectedPatient!;

                              // ==================================================
                              // FIRST: ADD PATIENT USING EXISTING SERVICE
                              // ==================================================

                              final queuePatient =
                                  await QueueService.addExistingPatientToQueue(
                                    patient,
                                  );

                              // ==================================================
                              // SECOND: IF A DOCTOR WAS SELECTED,
                              // OVERRIDE THE QUEUE DOCTOR
                              // ==================================================

                              if (selectedDoctorId != null &&
                                  queuePatient.id != null) {
                                await Supabase.instance.client
                                    .from("queue")
                                    .update({"doctor_id": selectedDoctorId})
                                    .eq("id", queuePatient.id!);
                              }

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              await loadQueue();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedDoctorId == null
                                        ? "${patient.name} added as "
                                              "${queuePatient.number} "
                                              "for ${patient.doctorName ?? "No doctor"}."
                                        : "${patient.name} added as "
                                              "${queuePatient.number} "
                                              "for $selectedDoctorName.",
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                          },
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading patients: $e")));
    }
  }

  // ============================================================
  // CALL NEXT PATIENT
  // ============================================================

  Future<void> callNextPatient() async {
    if (isProcessing) return;

    final current = currentPatient;

    if (current != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${current.number} is already being served.")),
      );

      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      QueuePatient? nextPatient;

      if (selectedDoctorId != null) {
        nextPatient = await QueueService.serveNextPatientForDoctor(
          selectedDoctorId!,
        );
      } else {
        nextPatient = await QueueService.serveNextPatient();
      }

      await loadQueue();

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      if (nextPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedDoctorId == null
                  ? "No waiting patients."
                  : "No waiting patients for "
                        "$selectedDoctorName.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${nextPatient.number} is now being served "
              "by ${nextPatient.doctorName ?? selectedDoctorName}.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ============================================================
  // COMPLETE CURRENT PATIENT
  // ============================================================

  Future<void> completeCurrentPatient() async {
    if (isProcessing) return;

    final current = currentPatient;

    if (current == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No current patient.")));

      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      QueuePatient? nextPatient;

      if (selectedDoctorId != null) {
        nextPatient = await QueueService.completeCurrentAndServeNextForDoctor(
          selectedDoctorId!,
        );
      } else {
        nextPatient = await QueueService.completeCurrentAndServeNext();
      }

      await loadQueue();

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      if (nextPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${current.number} completed. "
              "No waiting patients.",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${current.number} completed. "
              "${nextPatient.number} is now being served.",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ============================================================
  // MANUAL STATUS CHANGE
  // ============================================================

  Future<void> changeStatus(QueuePatient patient, String newStatus) async {
    try {
      await QueueService.updatePatient(
        QueuePatient(
          id: patient.id,
          number: patient.number,
          name: patient.name,
          status: newStatus,
          doctorId: patient.doctorId,
          doctorName: patient.doctorName,
          specialty: patient.specialty,
        ),
      );

      await loadQueue();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${patient.number} status changed to $newStatus"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ============================================================
  // DELETE QUEUE ENTRY
  // ============================================================

  Future<void> deletePatient(QueuePatient patient) async {
    if (patient.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Delete Queue Entry",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: Text(
            "Are you sure you want to remove "
            "${patient.name} from the queue?",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              icon: const Icon(Icons.delete),

              label: const Text("Delete"),

              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await QueueService.deletePatient(patient.id!);

      await loadQueue();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Queue entry deleted successfully")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    switch (status) {
      case "Current":
        return Colors.orange;

      case "Completed":
        return Colors.green;

      case "Waiting":
      default:
        return Colors.blue;
    }
  }

  // ============================================================
  // DOCTOR FILTER
  // ============================================================

  Widget buildDoctorFilter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),

      padding: const EdgeInsets.symmetric(horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedDoctorId,
          isExpanded: true,

          hint: const Text("Select Doctor"),

          icon: const Icon(Icons.arrow_drop_down),

          items: [
            const DropdownMenuItem<int?>(
              value: null,

              child: Row(
                children: [
                  Icon(Icons.groups, color: Colors.blue),

                  SizedBox(width: 10),

                  Text(
                    "All Doctors",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            ...doctors.map((doctor) {
              final id = doctor["id"] is int
                  ? doctor["id"] as int
                  : int.tryParse(doctor["id"]?.toString() ?? "");

              final name = doctor["name"]?.toString() ?? "";

              final specialty = doctor["specialty"]?.toString() ?? "";

              return DropdownMenuItem<int?>(
                value: id,

                child: Row(
                  children: [
                    const Icon(Icons.medical_services, color: Colors.blue),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        specialty.isEmpty ? name : "$name - $specialty",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          onChanged: isProcessing
              ? null
              : (value) {
                  setState(() {
                    selectedDoctorId = value;
                  });
                },
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget buildStatistics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),

      child: Row(
        children: [
          Expanded(
            child: _buildCounterCard(
              title: "WAITING",
              value: waitingCount.toString(),
              icon: Icons.hourglass_empty,
              color: Colors.orange,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _buildCounterCard(
              title: "CURRENT",
              value: currentPatient == null ? "0" : "1",
              icon: Icons.person,
              color: Colors.blue,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: _buildCounterCard(
              title: "DONE",
              value: completedCount.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUNTER CARD
  // ============================================================

  Widget _buildCounterCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(icon, color: color, size: 25),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PATIENT CARD
  // ============================================================

  Widget buildPatientCard(QueuePatient patient) {
    final statusColor = getStatusColor(patient.status);

    final hasDoctor =
        patient.doctorName != null && patient.doctorName!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      elevation: 3,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: CircleAvatar(
          radius: 28,

          backgroundColor: statusColor.withValues(alpha: 0.12),

          child: FittedBox(
            child: Text(
              patient.number,

              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ),

        title: Text(
          patient.name,

          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  patient.status,

                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(
                    Icons.medical_services,
                    size: 15,
                    color: Colors.blue,
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      hasDoctor
                          ? patient.specialty == null ||
                                    patient.specialty!.isEmpty
                                ? "Doctor: "
                                      "${patient.doctorName}"
                                : "Doctor: "
                                      "${patient.doctorName} • "
                                      "${patient.specialty}"
                          : "Doctor: Not assigned",

                      style: TextStyle(
                        fontSize: 12,
                        color: hasDoctor ? Colors.blueGrey : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        trailing: PopupMenuButton<String>(
          onSelected: isProcessing
              ? null
              : (value) {
                  switch (value) {
                    case "Waiting":
                      changeStatus(patient, "Waiting");
                      break;

                    case "Current":
                      changeStatus(patient, "Current");
                      break;

                    case "Completed":
                      changeStatus(patient, "Completed");
                      break;

                    case "Delete":
                      deletePatient(patient);
                      break;
                  }
                },

          itemBuilder: (context) => [
            const PopupMenuItem(value: "Waiting", child: Text("Waiting")),

            const PopupMenuItem(value: "Current", child: Text("Current")),

            const PopupMenuItem(value: "Completed", child: Text("Completed")),

            const PopupMenuDivider(),

            const PopupMenuItem(
              value: "Delete",
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final displayedPatients = filteredPatients;

    final current = currentPatient;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Hospital Queue",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: isProcessing ? null : callNextPatient,
            icon: const Icon(Icons.play_arrow),
            tooltip: "Call Next Patient",
          ),

          IconButton(
            onPressed: isProcessing ? null : loadData,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildDoctorFilter(),

                buildStatistics(),

                if (current != null)
                  Container(
                    width: double.infinity,

                    margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),

                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,

                      borderRadius: BorderRadius.circular(15),

                      border: Border.all(color: Colors.orange, width: 2),
                    ),

                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.orange,
                          size: 34,
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                "NOW SERVING",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),

                              Text(
                                current.number,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              if (current.doctorName != null &&
                                  current.doctorName!.isNotEmpty)
                                Text(
                                  current.doctorName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : completeCurrentPatient,
                          icon: const Icon(Icons.check_circle),
                          label: const Text("DONE"),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),

                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDoctorId == null
                              ? "All Patients"
                              : "$selectedDoctorName Queue",

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        "${displayedPatients.length}",

                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: displayedPatients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.queue_outlined,
                                size: 70,
                                color: Colors.grey.shade400,
                              ),

                              const SizedBox(height: 12),

                              Text(
                                selectedDoctorId == null
                                    ? "No patients in queue"
                                    : "No patients for "
                                          "$selectedDoctorName",

                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadData,

                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 5, 16, 90),

                            itemCount: displayedPatients.length,

                            itemBuilder: (context, index) {
                              return buildPatientCard(displayedPatients[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isProcessing ? null : showAddToQueueDialog,

        icon: const Icon(Icons.person_add),

        label: const Text("Add to Queue"),
      ),
    );
  }
}
