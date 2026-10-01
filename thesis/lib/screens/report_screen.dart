import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = true;
  String? errorMessage;

  int totalCompleted = 0;
  int totalWaiting = 0;
  int totalCurrent = 0;
  int totalCancelled = 0;

  List<Map<String, dynamic>> doctorReports = [];

  @override
  void initState() {
    super.initState();
    loadDailyReport();
  }

  // ============================================================
  // LOAD DAILY REPORT
  // ============================================================

  Future<void> loadDailyReport() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final now = DateTime.now();

      final startOfDay = DateTime(now.year, now.month, now.day);

      final endOfDay = startOfDay.add(const Duration(days: 1));

      // ========================================================
      // GET QUEUE DATA
      // ========================================================

      final response = await supabase
          .from('queue')
          .select('*, doctors(id, name, specialty)')
          .order('id', ascending: true);

      final List<dynamic> patients = response.where((item) {
        final patient = Map<String, dynamic>.from(item);

        final status = patient['status']?.toString().toLowerCase().trim();

        DateTime? createdAt;
        DateTime? completedAt;

        if (patient['created_at'] != null) {
          createdAt = DateTime.tryParse(patient['created_at'].toString());
        }

        if (patient['completed_at'] != null) {
          completedAt = DateTime.tryParse(patient['completed_at'].toString());
        }

        final isCreatedToday =
            createdAt != null &&
            !createdAt.isBefore(startOfDay) &&
            createdAt.isBefore(endOfDay);

        final isCompletedToday =
            completedAt != null &&
            !completedAt.isBefore(startOfDay) &&
            completedAt.isBefore(endOfDay);

        final isCompleted = status == 'completed' || status == 'done';

        if (isCompleted) {
          return isCompletedToday;
        }

        return isCreatedToday;
      }).toList();

      // ========================================================
      // GLOBAL COUNTERS
      // ========================================================

      int completed = 0;
      int waiting = 0;
      int current = 0;
      int cancelled = 0;

      for (final item in patients) {
        final patient = Map<String, dynamic>.from(item);

        final status = patient['status']?.toString().toLowerCase().trim();

        switch (status) {
          case 'completed':
          case 'done':
            completed++;
            break;

          case 'waiting':
            waiting++;
            break;

          case 'current':
          case 'serving':
            current++;
            break;

          case 'cancelled':
          case 'canceled':
            cancelled++;
            break;
        }
      }

      // ========================================================
      // GET DOCTORS
      // ========================================================

      final Map<int, Map<String, dynamic>> doctors = {};

      final doctorsResponse = await supabase
          .from('doctors')
          .select('id, name, specialty')
          .order('id', ascending: true);

      for (final item in doctorsResponse) {
        final doctor = Map<String, dynamic>.from(item);

        final doctorIdValue = doctor['id'];

        final int? doctorId = doctorIdValue is int
            ? doctorIdValue
            : int.tryParse(doctorIdValue?.toString() ?? '');

        if (doctorId == null) continue;

        doctors[doctorId] = {
          'id': doctorId,
          'name': doctor['name']?.toString() ?? 'Unknown Doctor',
          'specialty': doctor['specialty']?.toString() ?? '',
          'completed': 0,
          'waiting': 0,
          'current': 0,
          'cancelled': 0,
        };
      }

      // ========================================================
      // COUNT PATIENTS FOR EACH DOCTOR
      // ========================================================

      for (final item in patients) {
        final patient = Map<String, dynamic>.from(item);

        final doctorIdValue = patient['doctor_id'];

        final int? doctorId = doctorIdValue is int
            ? doctorIdValue
            : int.tryParse(doctorIdValue?.toString() ?? '');

        if (doctorId == null) continue;

        // ------------------------------------------------------
        // FALLBACK DOCTOR
        // ------------------------------------------------------

        if (!doctors.containsKey(doctorId)) {
          final nestedDoctor = patient['doctors'];

          String doctorName = 'Unknown Doctor';
          String specialty = '';

          if (nestedDoctor is Map) {
            doctorName = nestedDoctor['name']?.toString() ?? 'Unknown Doctor';

            specialty = nestedDoctor['specialty']?.toString() ?? '';
          }

          doctors[doctorId] = {
            'id': doctorId,
            'name': doctorName,
            'specialty': specialty,
            'completed': 0,
            'waiting': 0,
            'current': 0,
            'cancelled': 0,
          };
        }

        final status = patient['status']?.toString().toLowerCase().trim();

        switch (status) {
          case 'completed':
          case 'done':
            doctors[doctorId]!['completed'] =
                (doctors[doctorId]!['completed'] as int) + 1;
            break;

          case 'waiting':
            doctors[doctorId]!['waiting'] =
                (doctors[doctorId]!['waiting'] as int) + 1;
            break;

          case 'current':
          case 'serving':
            doctors[doctorId]!['current'] =
                (doctors[doctorId]!['current'] as int) + 1;
            break;

          case 'cancelled':
          case 'canceled':
            doctors[doctorId]!['cancelled'] =
                (doctors[doctorId]!['cancelled'] as int) + 1;
            break;
        }
      }

      // ========================================================
      // BUILD REPORT
      // ========================================================

      final reports = doctors.values.map((doctor) {
        final completed = doctor['completed'] as int;
        final waiting = doctor['waiting'] as int;
        final current = doctor['current'] as int;
        final cancelled = doctor['cancelled'] as int;

        final total = completed + waiting + current + cancelled;

        return {...doctor, 'total': total};
      }).toList();

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        totalCompleted = completed;
        totalWaiting = waiting;
        totalCurrent = current;
        totalCancelled = cancelled;

        doctorReports = reports;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Daily Report Error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String get formattedDate {
    final now = DateTime.now();

    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;

    return '$day/$month/$year';
  }

  // ============================================================
  // TOTAL ACTIVITY
  // ============================================================

  int get totalActivity {
    return totalCompleted + totalWaiting + totalCurrent + totalCancelled;
  }

  // ============================================================
  // COMPLETION RATE
  // ============================================================

  int get completionRate {
    if (totalActivity == 0) {
      return 0;
    }

    return ((totalCompleted / totalActivity) * 100).round();
  }

  // ============================================================
  // GLOBAL STAT CARD
  // ============================================================

  Widget statCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
    required Color background,
  }) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfffaf7fc),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: background,
            child: Icon(icon, size: 30, color: color),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 45,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff202024),
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '$value',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTOR STAT
  // ============================================================

  Widget doctorStat({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      height: 125,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 5),

          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCTOR CARD
  // ============================================================

  Widget doctorCard(Map<String, dynamic> doctor) {
    final name = doctor['name']?.toString() ?? 'Unknown Doctor';

    final specialty = doctor['specialty']?.toString() ?? '';

    final completed = doctor['completed'] as int;
    final waiting = doctor['waiting'] as int;
    final current = doctor['current'] as int;
    final cancelled = doctor['cancelled'] as int;
    final total = doctor['total'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xfffaf7fc),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;

          return Column(
            children: [
              // ==================================================
              // DOCTOR HEADER
              // ==================================================
              if (!narrow)
                Row(
                  children: [
                    doctorIcon(),

                    const SizedBox(width: 18),

                    Expanded(child: doctorName(name, specialty)),

                    const SizedBox(width: 15),

                    totalBadge(total),
                  ],
                )
              else
                Column(
                  children: [
                    doctorIcon(),

                    const SizedBox(height: 12),

                    doctorName(name, specialty, centered: true),

                    const SizedBox(height: 12),

                    totalBadge(total),
                  ],
                ),

              const SizedBox(height: 25),

              // ==================================================
              // DOCTOR STATISTICS
              // ==================================================
              GridView.count(
                crossAxisCount: narrow ? 2 : 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: narrow ? 1.55 : 1.65,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  doctorStat(
                    icon: Icons.check_circle,
                    value: completed,
                    label: 'Completed',
                    color: const Color(0xff4caf50),
                    background: const Color(0xffe8f5e9),
                  ),

                  doctorStat(
                    icon: Icons.hourglass_empty,
                    value: waiting,
                    label: 'Waiting',
                    color: const Color(0xffff9800),
                    background: const Color(0xfffff3e0),
                  ),

                  doctorStat(
                    icon: Icons.person,
                    value: current,
                    label: 'Current',
                    color: const Color(0xff3f51b5),
                    background: const Color(0xffe8eaf6),
                  ),

                  doctorStat(
                    icon: Icons.cancel,
                    value: cancelled,
                    label: 'Cancelled',
                    color: const Color(0xfff44336),
                    background: const Color(0xffffe5e8),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // DOCTOR ICON
  // ============================================================

  Widget doctorIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xffe0f2ff),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.medical_services,
        size: 38,
        color: Color(0xff2196f3),
      ),
    );
  }

  // ============================================================
  // DOCTOR NAME
  // ============================================================

  Widget doctorName(String name, String specialty, {bool centered = false}) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 5),

        Text(
          specialty,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(fontSize: 19, color: Colors.grey),
        ),
      ],
    );
  }

  // ============================================================
  // TOTAL BADGE
  // ============================================================

  Widget totalBadge(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffe1f2ff),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        'Total: $total',
        style: const TextStyle(
          color: Color(0xff2196f3),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget errorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),

            const SizedBox(height: 15),

            const Text(
              'Failed to load Daily Report',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: loadDailyReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
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
    return Scaffold(
      backgroundColor: const Color(0xfffdf8ff),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xffe9e1f2),
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Daily Report',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: isLoading ? null : loadDailyReport,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? errorView()
          : RefreshIndicator(
              onRefresh: loadDailyReport,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.all(24),

                children: [
                  // ==========================================
                  // TITLE
                  // ==========================================
                  const Text(
                    'Daily Report',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Hospital queue activity for today',
                    style: TextStyle(fontSize: 19, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // ==========================================
                  // DATE
                  // ==========================================
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Color(0xff2196f3),
                        size: 28,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // ==========================================
                  // GLOBAL STATISTICS
                  // ==========================================
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      int columns;

                      if (width >= 1300) {
                        columns = 3;
                      } else if (width >= 700) {
                        columns = 2;
                      } else {
                        columns = 1;
                      }

                      return GridView.count(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: columns == 1 ? 2.4 : 2.15,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

                        children: [
                          statCard(
                            icon: Icons.check_circle,
                            title: 'Patients Served Today',
                            value: totalCompleted,
                            color: const Color(0xff4caf50),
                            background: const Color(0xffe0f2e5),
                          ),

                          statCard(
                            icon: Icons.hourglass_empty,
                            title: 'Waiting Now',
                            value: totalWaiting,
                            color: const Color(0xffff9800),
                            background: const Color(0xffffecd2),
                          ),

                          statCard(
                            icon: Icons.person,
                            title: 'Current Now',
                            value: totalCurrent,
                            color: const Color(0xff3f51b5),
                            background: const Color(0xffe1e4f8),
                          ),

                          statCard(
                            icon: Icons.cancel,
                            title: 'Cancelled Today',
                            value: totalCancelled,
                            color: const Color(0xfff44336),
                            background: const Color(0xffffe0e3),
                          ),

                          statCard(
                            icon: Icons.analytics,
                            title: 'Total Activity Today',
                            value: totalActivity,
                            color: const Color(0xff2196f3),
                            background: const Color(0xffdcecff),
                          ),

                          statCard(
                            icon: Icons.percent,
                            title: 'Completion Rate',
                            value: completionRate,
                            color: const Color(0xff9c27b0),
                            background: const Color(0xffefdafa),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 45),

                  // ==========================================
                  // DOCTORS
                  // ==========================================
                  const Text(
                    "Doctors' Daily Summary",
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Daily queue activity for each doctor',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),

                  const SizedBox(height: 25),

                  // ==========================================
                  // DOCTOR LIST
                  // ==========================================
                  if (doctorReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'No doctors found.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),

                  ...doctorReports.map((doctor) => doctorCard(doctor)),
                ],
              ),
            ),
    );
  }
}
