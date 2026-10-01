 import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../services/doctor_service.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  List<Doctor> doctors = [];

  bool isLoading = true;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  // ============================================================
  // LOAD DOCTORS
  // ============================================================

  Future<void> loadDoctors() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final result = await DoctorService.getDoctors();

      if (!mounted) return;

      setState(() {
        doctors = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading doctors: $e")));
    }
  }

  // ============================================================
  // ADD / EDIT DOCTOR DIALOG
  // ============================================================

  Future<void> showDoctorDialog({Doctor? doctor}) async {
    final nameController = TextEditingController(text: doctor?.name ?? '');

    final specialtyController = TextEditingController(
      text: doctor?.specialty ?? '',
    );

    final shift1StartController = TextEditingController(
      text: doctor?.shift1Start ?? '',
    );

    final shift1EndController = TextEditingController(
      text: doctor?.shift1End ?? '',
    );

    final shift2StartController = TextEditingController(
      text: doctor?.shift2Start ?? '',
    );

    final shift2EndController = TextEditingController(
      text: doctor?.shift2End ?? '',
    );

    bool isActive = doctor?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                doctor == null ? "Add Doctor" : "Edit Doctor",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // DOCTOR NAME
                    // ==================================================
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Doctor Name",
                        hintText: "e.g. Dr. Abdiasis",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // SPECIALTY
                    // ==================================================
                    TextField(
                      controller: specialtyController,
                      decoration: const InputDecoration(
                        labelText: "Specialty",
                        hintText: "e.g. Neurology",
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // SHIFT 1
                    // ==================================================
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Shift 1",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: shift1StartController,
                            decoration: const InputDecoration(
                              labelText: "Start",
                              hintText: "07:00 AM",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextField(
                            controller: shift1EndController,
                            decoration: const InputDecoration(
                              labelText: "End",
                              hintText: "12:00 PM",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // SHIFT 2
                    // ==================================================
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Shift 2 (Optional)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: shift2StartController,
                            decoration: const InputDecoration(
                              labelText: "Start",
                              hintText: "02:00 PM",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: TextField(
                            controller: shift2EndController,
                            decoration: const InputDecoration(
                              labelText: "End",
                              hintText: "07:00 PM",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // ACTIVE / INACTIVE
                    // ==================================================
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Active Doctor"),
                      subtitle: Text(
                        isActive
                            ? "Doctor is currently active"
                            : "Doctor is inactive",
                      ),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() {
                          isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // ============================================================
              // ACTIONS
              // ============================================================
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton.icon(
                  icon: Icon(doctor == null ? Icons.add : Icons.save),
                  label: Text(doctor == null ? "Add Doctor" : "Save Changes"),

                  onPressed: () async {
                    final name = nameController.text.trim();
                    final specialty = specialtyController.text.trim();

                    if (name.isEmpty || specialty.isEmpty) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Doctor name and specialty are required",
                          ),
                        ),
                      );

                      return;
                    }

                    try {
                      // ==================================================
                      // ADD DOCTOR
                      // ==================================================

                      if (doctor == null) {
                        final newDoctor = Doctor(
                          name: name,
                          specialty: specialty,
                          shift1Start: shift1StartController.text.trim().isEmpty
                              ? null
                              : shift1StartController.text.trim(),
                          shift1End: shift1EndController.text.trim().isEmpty
                              ? null
                              : shift1EndController.text.trim(),
                          shift2Start: shift2StartController.text.trim().isEmpty
                              ? null
                              : shift2StartController.text.trim(),
                          shift2End: shift2EndController.text.trim().isEmpty
                              ? null
                              : shift2EndController.text.trim(),
                          isActive: isActive,
                        );

                        await DoctorService.addDoctor(newDoctor);
                      }
                      // ==================================================
                      // UPDATE DOCTOR
                      // ==================================================
                      else {
                        final updatedDoctor = Doctor(
                          id: doctor.id,
                          name: name,
                          specialty: specialty,
                          shift1Start: shift1StartController.text.trim().isEmpty
                              ? null
                              : shift1StartController.text.trim(),
                          shift1End: shift1EndController.text.trim().isEmpty
                              ? null
                              : shift1EndController.text.trim(),
                          shift2Start: shift2StartController.text.trim().isEmpty
                              ? null
                              : shift2StartController.text.trim(),
                          shift2End: shift2EndController.text.trim().isEmpty
                              ? null
                              : shift2EndController.text.trim(),
                          isActive: isActive,
                        );

                        await DoctorService.updateDoctor(updatedDoctor);
                      }

                      // ==================================================
                      // CLOSE DIALOG
                      // ==================================================

                      if (!dialogContext.mounted) return;

                      Navigator.of(dialogContext).pop();

                      // ==================================================
                      // RELOAD DOCTORS
                      // ==================================================

                      await loadDoctors();

                      // ==================================================
                      // SHOW SUCCESS MESSAGE
                      // ==================================================

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            doctor == null
                                ? "Doctor added successfully"
                                : "Doctor updated successfully",
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // ============================================================
    // DISPOSE CONTROLLERS
    // ============================================================

    nameController.dispose();
    specialtyController.dispose();
    shift1StartController.dispose();
    shift1EndController.dispose();
    shift2StartController.dispose();
    shift2EndController.dispose();
  }

  // ============================================================
  // DELETE DOCTOR
  // ============================================================

  Future<void> deleteDoctor(Doctor doctor) async {
    if (doctor.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete Doctor"),

          content: Text("Are you sure you want to delete ${doctor.name}?"),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },

              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() {
      isProcessing = true;
    });

    try {
      await DoctorService.deleteDoctor(doctor.id!);

      await loadDoctors();

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor deleted successfully")),
      );
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
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> toggleDoctor(Doctor doctor) async {
    if (doctor.id == null) return;

    try {
      await DoctorService.setDoctorActive(doctor.id!, !doctor.isActive);

      await loadDoctors();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            doctor.isActive
                ? "${doctor.name} is now inactive"
                : "${doctor.name} is now active",
          ),
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
  // SHIFT TEXT
  // ============================================================

  String getShiftText(Doctor doctor) {
    final shift1 = doctor.shift1Start != null && doctor.shift1End != null
        ? "${doctor.shift1Start} – ${doctor.shift1End}"
        : "";

    final shift2 = doctor.shift2Start != null && doctor.shift2End != null
        ? "${doctor.shift2Start} – ${doctor.shift2End}"
        : "";

    if (shift1.isNotEmpty && shift2.isNotEmpty) {
      return "$shift1  |  $shift2";
    }

    if (shift1.isNotEmpty) {
      return shift1;
    }

    if (shift2.isNotEmpty) {
      return shift2;
    }

    return "No shift assigned";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Doctors",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: isLoading ? null : loadDoctors,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : doctors.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "No doctors registered",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Add a doctor to get started",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: loadDoctors,

              child: ListView.builder(
                padding: const EdgeInsets.all(16),

                itemCount: doctors.length,

                itemBuilder: (context, index) {
                  final doctor = doctors[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),

                    elevation: 3,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        children: [
                          // ==================================================
                          // DOCTOR INFORMATION
                          // ==================================================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              CircleAvatar(
                                radius: 30,

                                backgroundColor: Colors.blue.shade50,

                                child: const Icon(
                                  Icons.medical_services,
                                  color: Colors.blue,
                                  size: 30,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      doctor.name,

                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Text(
                                      doctor.specialty,

                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 17,
                                          color: Colors.grey,
                                        ),

                                        const SizedBox(width: 5),

                                        Expanded(
                                          child: Text(
                                            getShiftText(doctor),

                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ==================================================
                              // ACTIVE STATUS
                              // ==================================================
                              Column(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: doctor.isActive
                                        ? Colors.green
                                        : Colors.red,
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    doctor.isActive ? "Active" : "Inactive",

                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: doctor.isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const Divider(height: 25),

                          // ==================================================
                          // ACTIONS
                          // ==================================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,

                            children: [
                              TextButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        toggleDoctor(doctor);
                                      },

                                icon: Icon(
                                  doctor.isActive
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                ),

                                label: Text(
                                  doctor.isActive ? "Deactivate" : "Activate",
                                ),
                              ),

                              const SizedBox(width: 5),

                              TextButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        showDoctorDialog(doctor: doctor);
                                      },

                                icon: const Icon(Icons.edit),

                                label: const Text("Edit"),
                              ),

                              const SizedBox(width: 5),

                              TextButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () {
                                        deleteDoctor(doctor);
                                      },

                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),

                                label: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

      // ============================================================
      // ADD DOCTOR
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isProcessing
            ? null
            : () {
                showDoctorDialog();
              },

        icon: const Icon(Icons.person_add),

        label: const Text("Add Doctor"),
      ),
    );
  }
}
