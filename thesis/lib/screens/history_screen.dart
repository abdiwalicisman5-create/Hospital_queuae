import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> historyList = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final data = await Supabase.instance.client
          .from('queue_history')
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        historyList = List<Map<String, dynamic>>.from(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: loadHistory, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!, textAlign: TextAlign.center))
          : historyList.isEmpty
          ? const Center(
              child: Text(
                "No history available",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final item = historyList[index];

                  final patientName =
                      item['patient_name']?.toString().trim().isNotEmpty == true
                      ? item['patient_name'].toString()
                      : "Unknown Patient";

                  final doctorName =
                      item['doctor_name']?.toString().trim().isNotEmpty == true
                      ? item['doctor_name'].toString()
                      : "Unknown Doctor";

                  final number = item['number']?.toString() ?? "";

                  final historyDate = item['history_date']?.toString() ?? "";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(
                        patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(doctorName),
                          if (number.isNotEmpty) Text("Queue: $number"),
                        ],
                      ),
                      trailing: historyDate.isEmpty
                          ? null
                          : Text(
                              historyDate,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
