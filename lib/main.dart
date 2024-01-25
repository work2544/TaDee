import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:tadeeflutter/constants.dart';
import 'package:location/location.dart';
import 'package:tadeeflutter/objectvision.dart';
import 'package:tadeeflutter/speechscreen.dart';
import 'package:tadeeflutter/uploadimage.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner:false,
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

  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;

  Future<void> getCurrentLocation() async {
    Location location = Location();
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

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
          const Text(
            'Enter your destination',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(
            height: 30,
          ),
          TextField(
            controller: latController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'latitude',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          TextField(
            controller: lngController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'longitute',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () async {
                  await launchUrl(Uri.parse(
                      'https://www.google.com/maps/dir/?api=1&destination=${double.parse(latController.text)},${double.parse(lngController.text)}&travelmode=walking'));
                },
                child: const Text('Get Directions')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ObjectVision()));
                },
                child: const Text('Go ML')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const SpeechScreen()));
                },
                child: const Text('Go Speech to text')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>  const UploadImage()));
                },
                child: const Text('Go upload image')),
          ),
        ]),
      ),
    );
    
  }
}
