import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://qyvbetyovtvmnqirnimd.supabase.co',
      publishableKey: 'sb_publishable_06Wg43Ad8U9b2cRlZkHz8Q_FabRQ13w',
    );

    debugPrint('SUPABASE INITIALIZED SUCCESSFULLY');

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('SUPABASE INITIALIZATION ERROR: $e');
    debugPrint('$stackTrace');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                'Supabase Error:\n\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hospital Queue Management System',

      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),

      home: const AuthGate(),
    );
  }
}
