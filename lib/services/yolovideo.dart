import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:tadeeflutter/services/texttospeech.dart';

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  final int intputduration;
  const YoloVideo(
      {super.key, required this.vision, required this.intputduration});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> with WidgetsBindingObserver {
  //Camera
  late List<CameraDescription> cameras;
  late CameraController controller;
  CameraImage? cameraImage;

  //YOLO
  bool isLoaded = false;
  bool isDetecting = false;
  //static const String _modelPath = 'assets/yolov8n_float32.tflite';
  //static const String _labelPath = 'assets/yolov8n_float32_labels.txt';
  static const String _modellocationPath = 'assets/location_float32.tflite';
  static const String _locationlabelPath = 'assets/location.txt';
  Timer? _timer;

  late List<Map<String, dynamic>> yoloResults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsFlutterBinding.ensureInitialized();
    init();
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    await controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
          WidgetsBinding.instance.addPostFrameCallback((_) => startDetection());
        });
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    stopDetection();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
        ...displayBoxesAroundRecognizedObjects(size)
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        // labels: _labelPath,
        // modelPath: _modelPath,
        labels: _locationlabelPath,
        modelPath: _modellocationPath,
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: true);
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.5,
        confThreshold: 0.6,
        classThreshold: 0.7);
    if (result.isNotEmpty) {
      Map<String, Set<String>> obstruct = {
        'ด้านซ้าย': {},
        'ด้านหน้า': {},
        'ด้านขวา': {}
      };
      String stringBuild = "";

      for (var i = 0; i < result.length; i++) {
        double startX = result[i]["box"][0];
        double endX = result[i]["box"][2];

        if (startX >= 0 && endX <= 155) {
          obstruct['ด้านซ้าย']!.add(result[i]['tag']);
        } else if (startX >= 325 && endX <= 480) {
          obstruct['ด้านขวา']!.add(result[i]['tag']);
        } else {
          obstruct['ด้านหน้า']!.add(result[i]['tag']);
        }
      }
      for (var k in obstruct.keys) {
        log('$k : ${obstruct[k].toString()}');
        if (obstruct[k]!.isNotEmpty) {
          stringBuild += '$k มี ${obstruct[k].toString()}';
        }
        result.clear();
      }
      TextToSpeech().speak(stringBuild);
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

    _timer = Timer.periodic(Duration(seconds: widget.intputduration), (timer) {
      if (isDetecting) {
        Timer(const Duration(milliseconds: 1000), () {
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
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  void stopStream() {
    if (controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
  }

  Future<void> stopDetection() async {
    isDetecting = false;
    yoloResults.clear();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];
    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
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
