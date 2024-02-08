import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tadeeflutter/backGroundnotification.dart';
import 'package:tadeeflutter/objectvision.dart';
import 'package:tadeeflutter/speechscreen.dart';
import 'package:tadeeflutter/uploadimage.dart';
import 'package:url_launcher/url_launcher.dart';

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
  TextEditingController latController = TextEditingController();
  TextEditingController lngController = TextEditingController();

  // late bool _serviceEnabled;
  // late PermissionStatus _permissionGranted;

  Future<void> getCurrentLocation() async {
    await Permission.microphone.request();
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.notification.request();
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaDee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ObjectVision()));
                },
                child: const Text('ML')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const SpeechScreen()));
                },
                child: const Text('Speech to text')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const UploadImage()));
                },
                child: const Text('Upload image')),
          ),
        ]),
      ),
    );
  }
}
