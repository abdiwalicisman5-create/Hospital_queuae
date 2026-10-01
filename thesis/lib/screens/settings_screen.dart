import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  // =========================
  // LOGOUT
  // =========================

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Logout error: $e")));
    }
  }

  // =========================
  // PROFILE
  // =========================

  void showProfile() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Administrator Profile"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("Hospital Admin"),

              SizedBox(height: 15),

              Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("admin@hospital.com"),

              SizedBox(height: 15),

              Text("Role", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("Administrator"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // SECURITY
  // =========================

  void showSecurity() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Privacy & Security"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.security, color: Colors.green),
                title: Text("Authentication"),
                subtitle: Text("Protected by Supabase Authentication"),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock, color: Colors.blue),
                title: Text("Data Security"),
                subtitle: Text("Patient data is stored securely."),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // ABOUT
  // =========================

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: "Hospital Queue Management System",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(
        Icons.local_hospital,
        color: Colors.blue,
        size: 40,
      ),
      children: const [
        SizedBox(height: 15),
        Text(
          "A digital hospital queue management system "
          "designed to manage patients, queues, and "
          "queue status efficiently.",
        ),
      ],
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // =========================
          // ADMIN PROFILE
          // =========================
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              "Hospital Admin",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 5),

          const Center(
            child: Text(
              "admin@hospital.com",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 30),

          // =========================
          // PROFILE
          // =========================
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text("Profile"),
              subtitle: const Text("View administrator profile"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: showProfile,
            ),
          ),

          // =========================
          // NOTIFICATIONS
          // =========================
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text("Notifications"),
              subtitle: const Text("Manage notification settings"),
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
          ),

          // =========================
          // SECURITY
          // =========================
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock, color: Colors.red),
              title: const Text("Privacy & Security"),
              subtitle: const Text("Security settings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: showSecurity,
            ),
          ),

          // =========================
          // ABOUT
          // =========================
          Card(
            child: ListTile(
              leading: const Icon(Icons.info, color: Colors.green),
              title: const Text("About"),
              subtitle: const Text("Hospital Queue Management System"),
              trailing: const Text("v1.0.0"),
              onTap: showAbout,
            ),
          ),

          const SizedBox(height: 30),

          // =========================
          // LOGOUT
          // =========================
          SizedBox(
            width: double.infinity,
            height: 50,

            child: ElevatedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },

              icon: const Icon(Icons.logout),

              label: const Text("Logout"),
            ),
          ),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Hospital Queue Management System",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
