import 'package:flutter/material.dart';

import '../models/patient.dart';
import '../services/patient_service.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen({super.key});

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  List<Patient> patients = [];
  List<Map<String, dynamic>> doctors = [];

  bool isLoading = true;
  bool isSaving = false;

  String searchText = '';

  // ==========================================================
  // SELECTED PATIENTS
  // ==========================================================
  final Set<int> selectedPatientIds = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final patientData = await PatientService.getPatients();
      final doctorData = await PatientService.getDoctors();

      if (!mounted) return;

      setState(() {
        patients = patientData;
        doctors = doctorData;

        // Remove IDs that no longer exist
        selectedPatientIds.removeWhere(
          (id) => !patients.any((patient) => patient.id == id),
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  String getNextQueueNumber() {
    int maxNumber = 0;

    for (final patient in patients) {
      final number = int.tryParse(patient.queue);

      if (number != null && number > maxNumber) {
        maxNumber = number;
      }
    }

    return (maxNumber + 1).toString().padLeft(3, '0');
  }

  List<Patient> get filteredPatients {
    if (searchText.trim().isEmpty) {
      return patients;
    }

    final query = searchText.toLowerCase().trim();

    return patients.where((patient) {
      return patient.name.toLowerCase().contains(query) ||
          patient.phone.toLowerCase().contains(query) ||
          patient.queue.toLowerCase().contains(query);
    }).toList();
  }

  // ==========================================================
  // SELECT ALL
  // ==========================================================
  bool get allPatientsSelected {
    final validPatients = patients
        .where((patient) => patient.id != null)
        .toList();

    if (validPatients.isEmpty) {
      return false;
    }

    return validPatients.every(
      (patient) => selectedPatientIds.contains(patient.id),
    );
  }

  void toggleSelectAll() {
    setState(() {
      if (allPatientsSelected) {
        selectedPatientIds.clear();
      } else {
        for (final patient in patients) {
          if (patient.id != null) {
            selectedPatientIds.add(patient.id!);
          }
        }
      }
    });
  }

  void togglePatientSelection(Patient patient) {
    if (patient.id == null) return;

    setState(() {
      if (selectedPatientIds.contains(patient.id)) {
        selectedPatientIds.remove(patient.id);
      } else {
        selectedPatientIds.add(patient.id!);
      }
    });
  }

  // ==========================================================
  // DELETE SELECTED PATIENTS
  // ==========================================================
  Future<void> deleteSelectedPatients() async {
    if (selectedPatientIds.isEmpty) return;

    final selectedCount = selectedPatientIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Selected Patients',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete $selectedCount selected patient(s)?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Delete Selected'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        isSaving = true;
      });
    }

    try {
      final idsToDelete = List<int>.from(selectedPatientIds);

      for (final id in idsToDelete) {
        await PatientService.deletePatient(id);
      }

      if (!mounted) return;

      setState(() {
        selectedPatientIds.clear();
      });

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedCount patient(s) deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting selected patients: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ==========================================================
  // PATIENT DIALOG
  // ==========================================================
  Future<void> showPatientDialog({Patient? patient}) async {
    final bool isEditing = patient != null;

    final nameController = TextEditingController(text: patient?.name ?? '');

    final ageController = TextEditingController(text: patient?.age ?? '');

    final phoneController = TextEditingController(text: patient?.phone ?? '');

    final queueController = TextEditingController(
      text: patient?.queue ?? getNextQueueNumber(),
    );

    int? selectedDoctorId = patient?.doctorId;

    bool saving = false;

    final formKey = GlobalKey<FormState>();

    try {
      await showDialog(
        context: context,
        barrierDismissible: !saving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Patient' : 'Register Patient',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: nameController,
                            enabled: !saving,
                            decoration: const InputDecoration(
                              labelText: 'Patient Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter patient name';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          TextFormField(
                            controller: ageController,
                            enabled: !saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter age';
                              }

                              final age = int.tryParse(value.trim());

                              if (age == null || age <= 0) {
                                return 'Enter a valid age';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          TextFormField(
                            controller: phoneController,
                            enabled: !saving,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter phone number';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          TextFormField(
                            controller: queueController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Queue Number',
                              prefixIcon: Icon(Icons.queue),
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 15),

                          DropdownButtonFormField<int?>(
                            initialValue: selectedDoctorId,
                            decoration: const InputDecoration(
                              labelText: 'Doctor',
                              prefixIcon: Icon(Icons.medical_services),
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No doctor assigned'),
                              ),

                              ...doctors.map((doctor) {
                                final dynamic rawId = doctor['id'];

                                final int? id = rawId is int
                                    ? rawId
                                    : int.tryParse(rawId.toString());

                                final name = doctor['name']?.toString() ?? '';

                                final specialty =
                                    doctor['specialty']?.toString() ?? '';

                                return DropdownMenuItem<int?>(
                                  value: id,
                                  child: Text(
                                    specialty.isEmpty
                                        ? name
                                        : '$name - $specialty',
                                  ),
                                );
                              }),
                            ],
                            onChanged: saving
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      selectedDoctorId = value;
                                    });
                                  },
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              doctors.isEmpty
                                  ? 'No active doctors available'
                                  : '${doctors.length} active doctor(s) available',
                              style: TextStyle(
                                fontSize: 12,
                                color: doctors.isEmpty
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton.icon(
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isEditing ? Icons.save : Icons.person_add),
                    label: Text(
                      saving
                          ? 'Saving...'
                          : isEditing
                          ? 'Save Changes'
                          : 'Register',
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            final messenger = ScaffoldMessenger.of(context);

                            setDialogState(() {
                              saving = true;
                            });

                            if (mounted) {
                              setState(() {
                                isSaving = true;
                              });
                            }

                            try {
                              final newPatient = Patient(
                                id: patient?.id,
                                name: nameController.text.trim(),
                                age: ageController.text.trim(),
                                phone: phoneController.text.trim(),
                                queue: queueController.text.trim(),
                                doctorId: selectedDoctorId,
                              );

                              if (isEditing) {
                                await PatientService.updatePatient(newPatient);
                              } else {
                                await PatientService.addPatient(newPatient);
                              }

                              if (!dialogContext.mounted) {
                                return;
                              }

                              Navigator.of(dialogContext).pop();

                              await loadData();

                              if (!mounted) return;

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Patient updated successfully'
                                        : 'Patient registered successfully',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  saving = false;
                                });
                              }

                              if (!mounted) return;

                              setState(() {
                                isSaving = false;
                              });

                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')),
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
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }

      nameController.dispose();
      ageController.dispose();
      phoneController.dispose();
      queueController.dispose();
    }
  }

  // ==========================================================
  // DELETE SINGLE PATIENT
  // ==========================================================
  Future<void> deletePatient(Patient patient) async {
    if (patient.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Patient',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to delete ${patient.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await PatientService.deletePatient(patient.id!);

      if (mounted) {
        setState(() {
          selectedPatientIds.remove(patient.id);
        });
      }

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting patient: $e')));
    }
  }

  // ==========================================================
  // PATIENT CARD
  // ==========================================================
  Widget buildPatientCard(Patient patient) {
    final bool hasDoctor =
        patient.doctorName != null && patient.doctorName!.isNotEmpty;

    final bool isSelected =
        patient.id != null && selectedPatientIds.contains(patient.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // ==================================================
            // CHECKBOX
            // ==================================================
            Checkbox(
              value: isSelected,
              onChanged: isSaving
                  ? null
                  : patient.id == null
                  ? null
                  : (_) {
                      togglePatientSelection(patient);
                    },
            ),

            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                patient.queue,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Age: ${patient.age} • Phone: ${patient.phone}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),

                  const SizedBox(height: 5),

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
                          !hasDoctor
                              ? 'Doctor: Not assigned'
                              : patient.specialty == null ||
                                    patient.specialty!.isEmpty
                              ? 'Doctor: ${patient.doctorName}'
                              : 'Doctor: ${patient.doctorName} • ${patient.specialty}',
                          style: TextStyle(
                            fontSize: 13,
                            color: !hasDoctor ? Colors.orange : Colors.blueGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: isSaving
                      ? null
                      : () {
                          showPatientDialog(patient: patient);
                        },
                  icon: const Icon(Icons.edit, color: Colors.blue),
                ),

                IconButton(
                  tooltip: 'Delete',
                  onPressed: isSaving
                      ? null
                      : () {
                          deletePatient(patient);
                        },
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final displayedPatients = filteredPatients;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading || isSaving ? null : loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ==================================================
                // REGISTER BUTTON
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () {
                              showPatientDialog();
                            },
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        'Register New Patient',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // SEARCH
                // ==================================================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone or queue number',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchText.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  searchText = '';
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),

                // ==================================================
                // TOTAL + SELECT ALL + DELETE SELECTED
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total Patients: ${patients.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (selectedPatientIds.isNotEmpty)
                        Text(
                          '${selectedPatientIds.length} selected',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),

                // ==================================================
                // SELECT ALL / DELETE SELECTED
                // ==================================================
                if (patients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving ? null : toggleSelectAll,
                            icon: Icon(
                              allPatientsSelected
                                  ? Icons.deselect
                                  : Icons.select_all,
                            ),
                            label: Text(
                              allPatientsSelected
                                  ? 'Unselect All'
                                  : 'Select All',
                            ),
                          ),
                        ),

                        if (selectedPatientIds.isNotEmpty) ...[
                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: isSaving
                                  ? null
                                  : deleteSelectedPatients,
                              icon: const Icon(Icons.delete_sweep),
                              label: Text(
                                'Delete Selected (${selectedPatientIds.length})',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // ==================================================
                // PATIENT LIST
                // ==================================================
                Expanded(
                  child: displayedPatients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 70,
                                color: Colors.grey.shade400,
                              ),

                              const SizedBox(height: 12),

                              Text(
                                searchText.isEmpty
                                    ? 'No patients registered'
                                    : 'No patients found',
                                style: const TextStyle(
                                  fontSize: 18,
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

      // ==========================================================
      // ADD PATIENT
      // ==========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving
            ? null
            : () {
                showPatientDialog();
              },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Patient'),
      ),
    );
  }
}
