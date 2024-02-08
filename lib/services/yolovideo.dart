import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tadeeflutter/services/texttospeech.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('ic_bg_service_small'),
    ),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // DartPluginRegistrant.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final objects = preferences.getStringList('objects') ?? <String>[];

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  objects.forEach((element) {
    TextToSpeech().speak(element);
  });

  Timer.periodic(const Duration(seconds: 3), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Updated at ${DateTime.now()}",
        );
      }
    }

    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }
  });
}

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  const YoloVideo({super.key, required this.vision});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  //Camera
  late List<CameraDescription> cameras;
  late CameraController controller;
  CameraImage? cameraImage;

  //YOLO
  late List<Map<String, dynamic>> yoloResults;
  bool isLoaded = false;
  bool isDetecting = false;
  static const String _modelPath = 'assets/yolov8n_float32.tflite';
  static const String _labelPath = 'assets/yolov8n_float32_labels.txt';

  //BackGroundService
  final service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    initializeService();
    init();
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
        });
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(
            controller,
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size),
        Positioned(
          bottom: 75,
          width: MediaQuery.of(context).size.width,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  width: 5, color: Colors.white, style: BorderStyle.solid),
            ),
            child: isDetecting
                ? IconButton(
                    onPressed: () async {
                      stopDetection();
                    },
                    icon: const Icon(
                      Icons.stop,
                      color: Colors.red,
                    ),
                    iconSize: 50,
                  )
                : IconButton(
                    onPressed: () async {
                      await startDetection();
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                    iconSize: 50,
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: _labelPath,
        modelPath: _modelPath,
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: false);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.6,
        classThreshold: 0.6);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });

    if (controller.value.isStreamingImages) {
      return;
    }
    var isRunning = await service.isRunning();
    if (!isRunning) {
      FlutterBackgroundService().invoke("setAsForeground");
      service.startService();
    }

    Timer.periodic(const Duration(seconds: 5), (timer) {
      log('interval');
      if (isDetecting) {
        Timer(const Duration(milliseconds: 2000), () {
          startStream();
          Timer(const Duration(milliseconds: 1000), () {
            stopStream();
          });
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> startStream() async {
    await controller.startImageStream((image) {
      if (isDetecting) {
        log('Start image stream');
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  void stopStream() {
    if (controller.value.isStreamingImages) {
      log('Stopping image stream');
      controller.stopImageStream();
    }
  }

  Future<void> stopDetection() async {
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    }
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  void getOject() async {
    List<String> objects = [];
    yoloResults.map((result) {
      objects.add(result['tag']);
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('objects', []);
    await preferences.setStringList('objects', objects);
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);
    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    getOject();
    return yoloResults.map((result) {
      // TextToSpeech().speak(result['tag']);
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
