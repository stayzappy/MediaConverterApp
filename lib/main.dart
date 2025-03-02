import 'package:flutter/material.dart';
import 'package:zapmediaconverter/models/notification_service.dart';
import 'package:zapmediaconverter/screens/convert_screen.dart';
import 'package:zapmediaconverter/models/utility_classes_and_methods.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await PermissionManager.checkAndRequestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      themeAnimationCurve: Curves.bounceInOut,
      home: const FileConverterScreen(),
    );
  }
}

