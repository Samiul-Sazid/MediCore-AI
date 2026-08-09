import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hive_service.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/medication_provider.dart';
import 'providers/document_provider.dart';
import 'providers/scanner_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/smartwatch_provider.dart';
import 'providers/history_provider.dart';
import 'providers/notification_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage engine
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize AuthProvider
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SmartwatchProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MediCoreApp(),
    ),
  );
}
