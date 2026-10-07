import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/seed_service.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SeedService.seedAdminAccount();
  await SeedService.seedColomboNationalHospital();
  await SeedService.cleanUpOtherHospitals();

  runApp(const OPDConnectApp());
}

class OPDConnectApp extends StatelessWidget {
  const OPDConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OPD Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}