import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/queue_patient.dart';
import '../services/queue_service.dart';

class MyQueueScreen extends StatefulWidget {
  const MyQueueScreen({super.key});

  @override
  State<MyQueueScreen> createState() => _MyQueueScreenState();
}

class _MyQueueScreenState extends State<MyQueueScreen> {
  // ============================================================
  // QUEUE DATA
  // ============================================================

  List<QueuePatient> queueList = [];

  // Patients currently being served
  List<QueuePatient> currentPatients = [];

  RealtimeChannel? _queueChannel;

  Timer? clockTimer;
  Timer? doctorRotationTimer;
  Timer? mediaTimer;

  DateTime now = DateTime.now();

  // Current doctor/page
  int doctorPage = 0;

  String currentAnimationKey = "empty";

  // ============================================================
  // MEDIA - 5 IMAGES
  // ============================================================

  final List<String> mediaItems = [
    'assets/media/image.1.jpg',
    'assets/media/image.2.jpg',
    'assets/media/image.3.jpg',
    'assets/media/image.4.jpg',
    'assets/media/image.5.jpg',
  ];

  int mediaIndex = 0;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadQueue();

    setupRealtime();

    _startImageTimer();

    // ==========================================================
    // CLOCK
    // ==========================================================

    clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        now = DateTime.now();
      });
    });

    // ==========================================================
    // DOCTOR ROTATION
    //
    // Every 8 seconds:
    // NOW SERVING changes
    // AND WAITING changes to the same doctor's queue
    // ==========================================================

    doctorRotationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;

      if (currentPatients.length > 1) {
        setState(() {
          doctorPage++;

          if (doctorPage >= currentPatients.length) {
            doctorPage = 0;
          }
        });
      }
    });
  }

  // ============================================================
  // IMAGE TIMER
  // ============================================================

  void _startImageTimer() {
    mediaTimer?.cancel();

    mediaTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || mediaItems.isEmpty) return;

      setState(() {
        mediaIndex++;

        if (mediaIndex >= mediaItems.length) {
          mediaIndex = 0;
        }
      });
    });
  }

  // ============================================================
  // LOAD QUEUE
  // ============================================================

  Future<void> loadQueue() async {
    try {
      final data = await QueueService.getQueue();

      if (!mounted) return;

      // ========================================================
      // GET CURRENT PATIENTS
      // ========================================================

      final newCurrentPatients = data
          .where((patient) => patient.status == "Current")
          .toList();

      // ========================================================
      // ANIMATION KEY
      // ========================================================

      String newAnimationKey = "empty";

      if (newCurrentPatients.isNotEmpty) {
        final current = newCurrentPatients.first;

        newAnimationKey =
            "${current.id}_"
            "${current.number}_"
            "${current.name}_"
            "${current.doctorId}_"
            "${current.status}";
      }

      // ========================================================
      // UPDATE STATE
      // ========================================================

      setState(() {
        queueList = data;

        currentPatients = newCurrentPatients;

        currentAnimationKey = newAnimationKey;

        if (currentPatients.isEmpty) {
          doctorPage = 0;
        } else if (doctorPage >= currentPatients.length) {
          doctorPage = 0;
        }
      });
    } catch (e) {
      debugPrint("Queue Display Error: $e");
    }
  }

  // ============================================================
  // SUPABASE REALTIME
  // ============================================================

  void setupRealtime() {
    _queueChannel = Supabase.instance.client
        .channel('tv-queue-realtime')
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    clockTimer?.cancel();

    doctorRotationTimer?.cancel();

    mediaTimer?.cancel();

    if (_queueChannel != null) {
      Supabase.instance.client.removeChannel(_queueChannel!);
    }

    super.dispose();
  }

  // ============================================================
  // ALL WAITING PATIENTS
  // ============================================================

  List<QueuePatient> get allWaitingPatients {
    return queueList.where((patient) => patient.status == "Waiting").toList();
  }

  // ============================================================
  // DISPLAYED CURRENT PATIENT
  // ============================================================

  QueuePatient? get displayedCurrentPatient {
    if (currentPatients.isEmpty) {
      return null;
    }

    if (doctorPage >= currentPatients.length) {
      return currentPatients.first;
    }

    return currentPatients[doctorPage];
  }

  // ============================================================
  // CURRENT DOCTOR ID
  //
  // This is VERY IMPORTANT.
  //
  // Waiting patients will be filtered using this doctor ID.
  // ============================================================

  int? get displayedDoctorId {
    return displayedCurrentPatient?.doctorId;
  }

  // ============================================================
  // WAITING PATIENTS FOR CURRENT DOCTOR
  //
  // THIS IS THE MAIN FIX.
  //
  // Example:
  //
  // Now Serving:
  // Dr. Liibaan
  //
  // Waiting:
  // Only patients whose doctor_id == Dr. Liibaan's doctor_id
  // ============================================================

  List<QueuePatient> get waitingPatientsForCurrentDoctor {
    final doctorId = displayedDoctorId;

    if (doctorId == null) {
      return [];
    }

    return queueList
        .where(
          (patient) =>
              patient.status == "Waiting" && patient.doctorId == doctorId,
        )
        .toList();
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  int get completedCount {
    return queueList.where((patient) => patient.status == "Completed").length;
  }

  // ============================================================
  // DATE
  // ============================================================

  String get formattedDate {
    return "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year}";
  }

  // ============================================================
  // TIME
  // ============================================================

  String get formattedTime {
    final hour = now.hour == 0
        ? 12
        : now.hour > 12
        ? now.hour - 12
        : now.hour;

    final minute = now.minute.toString().padLeft(2, '0');

    final second = now.second.toString().padLeft(2, '0');

    final period = now.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute:$second $period";
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 7, child: _buildQueueSection()),

                  const SizedBox(width: 14),

                  Expanded(flex: 3, child: _buildMediaSection()),
                ],
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),

      decoration: const BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),

      child: Row(
        children: [
          // BACK BUTTON
          IconButton(
            tooltip: "Back",

            icon: const Icon(Icons.arrow_back, color: Colors.blue, size: 28),

            onPressed: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 4),

          // LOGO
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.local_hospital,
              color: Colors.blue,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          // TITLE
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "HOSPITAL",

                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),

                Text(
                  "PATIENT QUEUE MANAGEMENT SYSTEM",

                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // DATE + TIME
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                formattedTime,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                formattedDate,

                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUEUE SECTION
  // ============================================================

  Widget _buildQueueSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 18, bottom: 10),

      child: Column(
        children: [
          _buildNowServing(),

          const SizedBox(height: 16),

          Expanded(child: _buildWaitingSection()),
        ],
      ),
    );
  }

  // ============================================================
  // NOW SERVING
  // ============================================================

  Widget _buildNowServing() {
    final current = displayedCurrentPatient;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),

      reverseDuration: const Duration(milliseconds: 500),

      switchInCurve: Curves.easeOutCubic,

      switchOutCurve: Curves.easeInCubic,

      transitionBuilder: (Widget child, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,

          child: child,

          builder: (context, child) {
            final value = Curves.easeOutBack.transform(animation.value);

            final slide = (1 - animation.value) * 500;

            final rotate = (1 - animation.value) * 0.20;

            final scale = 0.78 + (value * 0.22);

            return Opacity(
              opacity: animation.value.clamp(0.0, 1.0),

              child: Transform(
                alignment: Alignment.center,

                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translateByDouble(slide, 0, 0, 1)
                  ..rotateY(rotate)
                  ..rotateZ(rotate * 0.25)
                  ..scaleByDouble(scale, scale, 1.0, 1.0),

                child: child,
              ),
            );
          },
        );
      },

      child: _buildCurrentCard(current, "${currentAnimationKey}_$doctorPage"),
    );
  }

  // ============================================================
  // CURRENT CARD
  // ============================================================

  Widget _buildCurrentCard(QueuePatient? current, String animationKey) {
    return Container(
      key: ValueKey(animationKey),

      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            flex: 6,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "NOW SERVING",

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 4),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),

                  child: Text(
                    current?.number ?? "---",

                    key: ValueKey(current?.number ?? "empty"),

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),

                  child: Text(
                    current?.name ?? "Please wait...",

                    key: ValueKey(current?.name ?? "no-patient"),

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 4,

            child: Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),

                borderRadius: BorderRadius.circular(18),
              ),

              child: Column(
                children: [
                  const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 36,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    current?.doctorName ?? "Doctor",

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (current?.specialty != null &&
                      current!.specialty!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),

                      child: Text(
                        current.specialty!,

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  const Text(
                    "PLEASE PROCEED",

                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WAITING SECTION
  //
  // IMPORTANT:
  // This section follows the CURRENT DOCTOR.
  // ============================================================

  Widget _buildWaitingSection() {
    final waiting = waitingPatientsForCurrentDoctor;

    final doctorName = displayedCurrentPatient?.doctorName ?? "Doctor";

    final doctorId = displayedCurrentPatient?.doctorId;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // WAITING HEADER
          // ======================================================
          Row(
            children: [
              const Icon(Icons.people_alt, color: Colors.orange, size: 25),

              const SizedBox(width: 8),

              const Text(
                "WAITING PATIENTS",

                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(width: 10),

              // CURRENT DOCTOR NAME
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),

                  child: Text(
                    doctorId == null ? "" : "• $doctorName",

                    key: ValueKey("$doctorId-$doctorName"),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // COUNT
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),

                child: Container(
                  key: ValueKey("$doctorId-${waiting.length}"),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,

                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    "${waiting.length}",

                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ======================================================
          // WAITING PATIENTS
          //
          // Animated together with doctor rotation.
          // ======================================================
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),

              switchInCurve: Curves.easeOutCubic,

              switchOutCurve: Curves.easeInCubic,

              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideAnimation =
                    Tween<Offset>(
                      begin: const Offset(0.25, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );

                return FadeTransition(
                  opacity: animation,

                  child: SlideTransition(
                    position: slideAnimation,

                    child: child,
                  ),
                );
              },

              child: waiting.isEmpty
                  ? Container(
                      key: ValueKey("empty-$doctorId"),

                      alignment: Alignment.center,

                      child: Text(
                        doctorId == null
                            ? "No doctor is currently serving"
                            : "No waiting patients for $doctorName",

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : GridView.builder(
                      key: ValueKey(
                        "$doctorId-${waiting.map((e) => e.id).join('-')}",
                      ),

                      physics: const BouncingScrollPhysics(),

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.5,
                          ),

                      itemCount: waiting.length,

                      itemBuilder: (context, index) {
                        return _buildWaitingCard(waiting[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WAITING CARD
  // ============================================================

  Widget _buildWaitingCard(QueuePatient patient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      decoration: BoxDecoration(
        color: Colors.orange.shade50,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: Colors.orange.shade100),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: Colors.orange,

              borderRadius: BorderRadius.circular(12),
            ),

            child: FittedBox(
              child: Text(
                patient.number,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  patient.name,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (patient.doctorName != null &&
                    patient.doctorName!.isNotEmpty)
                  Text(
                    patient.doctorName!,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEDIA SECTION
  // ============================================================

  Widget _buildMediaSection() {
    return Padding(
      padding: const EdgeInsets.only(right: 18, top: 18, bottom: 10),

      child: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),

          child: Column(
            children: [
              // HEADER
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(13),

                color: Colors.blue,

                child: const Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.white),

                    SizedBox(width: 8),

                    Text(
                      "INFORMATION",

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // MEDIA
              Expanded(child: _buildMediaContent()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDIA CONTENT
  // ============================================================

  Widget _buildMediaContent() {
    if (mediaItems.isEmpty) {
      return _buildMediaPlaceholder();
    }

    final currentMedia = mediaItems[mediaIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),

      switchInCurve: Curves.easeInOut,

      switchOutCurve: Curves.easeInOut,

      child: Image.asset(
        currentMedia,

        key: ValueKey(currentMedia),

        width: double.infinity,

        height: double.infinity,

        fit: BoxFit.cover,

        errorBuilder: (context, error, stackTrace) {
          return _buildMediaPlaceholder();
        },
      ),
    );
  }

  // ============================================================
  // MEDIA PLACEHOLDER
  // ============================================================

  Widget _buildMediaPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,

          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),

      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Icon(Icons.local_hospital, size: 75, color: Colors.blue),

          SizedBox(height: 18),

          Text(
            "WELCOME",

            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              letterSpacing: 2,
            ),
          ),

          SizedBox(height: 8),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25),

            child: Text(
              "Please wait for your queue number to be called.",

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
            ),
          ),

          SizedBox(height: 28),

          Icon(Icons.notifications_active, color: Colors.orange, size: 35),

          SizedBox(height: 7),

          Text(
            "PLEASE PAY ATTENTION",

            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    final currentDoctor = displayedCurrentPatient?.doctorName;

    final currentWaiting = waitingPatientsForCurrentDoctor.length;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),

      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.blue),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              currentDoctor == null
                  ? "Please proceed to your assigned doctor when your queue number is displayed."
                  : "Please proceed to $currentDoctor when your queue number is displayed.",

              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),

          const SizedBox(width: 15),

          Row(
            children: [
              const Icon(Icons.people, size: 18, color: Colors.orange),

              const SizedBox(width: 5),

              Text(
                "Waiting: $currentWaiting",

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 15),

              const Icon(Icons.check_circle, size: 18, color: Colors.green),

              const SizedBox(width: 5),

              Text(
                "Completed: $completedCount",

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
