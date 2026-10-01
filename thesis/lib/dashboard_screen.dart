import 'package:flutter/material.dart';

import 'widgets/drawer_menu.dart';
import 'components/dashboard_card.dart';

import 'services/patient_service.dart' as patient_service;
import 'services/queue_service.dart' as queue_service;

import 'screens/patient_screen.dart' as patient_screen;
import 'screens/queue_screen.dart' as queue_screen;
import 'screens/my_queue_screen.dart' as my_queue_screen;

import 'models/patient.dart';
import 'models/queue_patient.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // DATA
  // ============================================================

  List<Patient> patients = [];

  List<QueuePatient> queueList = [];

  bool isLoading = true;

  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadDashboardData();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> loadDashboardData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final patientData = await patient_service.PatientService.getPatients();

      final queueData = await queue_service.QueueService.getQueue();

      if (!mounted) return;

      setState(() {
        patients = patientData;
        queueList = queueData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // WAITING COUNT
  // ============================================================

  int get waitingCount {
    return queueList.where((patient) => patient.status == "Waiting").length;
  }

  // ============================================================
  // CURRENT COUNT
  // ============================================================

  int get currentCount {
    return queueList.where((patient) => patient.status == "Current").length;
  }

  // ============================================================
  // COMPLETED COUNT
  // ============================================================

  int get completedCount {
    return queueList.where((patient) => patient.status == "Completed").length;
  }

  // ============================================================
  // TODAY
  // ============================================================

  String get today {
    final now = DateTime.now();

    return "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadDashboardData,
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // ==========================================================
      // DRAWER
      // ==========================================================
      drawer: const DrawerMenu(),

      // ==========================================================
      // BODY
      // ==========================================================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // WELCOME
                    // ==================================================
                    const Text(
                      "Welcome 👋",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Hospital Queue Management System",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // DASHBOARD CARDS - ROW 1
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.people,
                            title: "Patients",
                            value: patients.length.toString(),
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: DashboardCard(
                            icon: Icons.queue,
                            title: "Queue",
                            value: queueList.length.toString(),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // DASHBOARD CARDS - ROW 2
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.hourglass_empty,
                            title: "Waiting",
                            value: waitingCount.toString(),
                            color: Colors.orange,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: DashboardCard(
                            icon: Icons.person,
                            title: "Current",
                            value: currentCount.toString(),
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // DASHBOARD CARDS - ROW 3
                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            icon: Icons.check_circle,
                            title: "Completed",
                            value: completedCount.toString(),
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: DashboardCard(
                            icon: Icons.calendar_today,
                            title: "Today",
                            value: today,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 35),

                    // ==================================================
                    // QUICK ACTIONS
                    // ==================================================
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ==================================================
                    // MANAGE PATIENTS
                    // ==================================================
                    _buildActionButton(
                      icon: Icons.people,
                      title: "Manage Patients",
                      color: Colors.blue,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const patient_screen.PatientScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboardData();
                      },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // MANAGE QUEUE
                    // ==================================================
                    _buildActionButton(
                      icon: Icons.queue,
                      title: "Manage Queue",
                      color: Colors.orange,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const queue_screen.QueueScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboardData();
                      },
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // PATIENT DISPLAY
                    // ==================================================
                    _buildActionButton(
                      icon: Icons.tv,
                      title: "Patient Display",
                      color: Colors.green,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const my_queue_screen.MyQueueScreen(),
                          ),
                        );

                        if (!mounted) return;

                        await loadDashboardData();
                      },
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),

            const SizedBox(height: 15),

            const Text(
              "Unable to load dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              errorMessage ?? "Unknown error",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
