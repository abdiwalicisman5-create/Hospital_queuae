 import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard_screen.dart';
import '../screens/patient_screen.dart';
import '../screens/queue_screen.dart';
import '../screens/doctor_screen.dart';
import '../screens/report_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';
import '../screens/history_screen.dart';

class DrawerMenu extends StatelessWidget {
  const DrawerMenu({super.key});

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // =========================
          // HEADER
          // =========================
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),

            accountName: Text(
              "Hospital Admin",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            accountEmail: Text("admin@hospital.com"),

            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,

              child: Icon(Icons.local_hospital, color: Colors.blue, size: 40),
            ),
          ),

          // =========================
          // DASHBOARD
          // =========================
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),

            onTap: () {
              Navigator.pop(context);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),

          // =========================
          // DOCTORS
          // =========================
          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.blue),

            title: const Text("Doctors"),

            subtitle: const Text("Manage Doctors"),

            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorScreen()),
              );
            },
          ),

          // =========================
          // QUEUE
          // =========================
          ListTile(
            leading: const Icon(Icons.queue),
            title: const Text("Queue"),

            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QueueScreen()),
              );
            },
          ),

          // =========================
          // PATIENTS
          // =========================
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Patients"),

            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PatientScreen()),
              );
            },
          ),

          // =========================
          // HISTORY
          // =========================
          ListTile(
            leading: const Icon(Icons.history, color: Colors.green),
            title: const Text("History"),

            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),

          // =========================
          // REPORTS
          // =========================
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Reports"),

            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReportScreen()),
              );
            },
          ),

          // =========================
          // SETTINGS
          // =========================
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),

            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const Divider(),

          // =========================
          // LOGOUT
          // =========================
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),

            title: const Text("Logout", style: TextStyle(color: Colors.red)),

            onTap: () async {
              Navigator.pop(context);

              await logout(context);
            },
          ),
        ],
      ),
    );
  }
}
