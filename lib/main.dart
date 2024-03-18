import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tadeeflutter/services/test.dart';
import 'package:tadeeflutter/speechscreen.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<void> getCurrentPermission() async {
    await Permission.microphone.request();
    await Permission.camera.request();
    await Permission.location.request();
  }

  @override
  void initState() {
    super.initState();
    getCurrentPermission();
    WakelockPlus.enable();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return  const SpeechScreen();
  // }
  @override
  Widget build(BuildContext context) {
    return const Test();
  }
}
