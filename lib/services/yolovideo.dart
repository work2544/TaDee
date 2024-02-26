import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';

import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:tadeeflutter/services/texttospeech.dart';

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

  @override
  void initState() {
    super.initState();
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
    stopDetection();
    controller.dispose();
    super.dispose();
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
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {

    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.6,
        classThreshold: 0.75);
    if (result.isNotEmpty) {
      Map<String, Set<String>> obstruct = {
        'ด้านซ้าย': {},
        'ด้านหน้า': {},
        'ด้านขวา': {}
      };
    
      for (var i = 0; i < result.length; i++) {

        double startX = result[i]["box"][0];
        double endX = result[i]["box"][2];
        log('${result[i]['tag']} : ($startX , $endX)');
        if (startX >= 0 && endX <= 155) {
          obstruct['left']!.add(result[i]['tag']);
        } else if (startX >= 325 && endX <= 480) {
          obstruct['right']!.add(result[i]['tag']);
        } else {
          obstruct['middle']!.add(result[i]['tag']);
        }
      }
      for (var k in obstruct.keys) {
        log('$k : ${obstruct[k].toString()}');
        TextToSpeech().speak('$k มี ${obstruct[k].toString()}');
      }
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

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isDetecting) {
        Timer(const Duration(milliseconds: 2000), () {
          startStream();
          Timer(const Duration(milliseconds: 1000), () {
            stopStream();
            if (yoloResults.isNotEmpty) {
              yoloResults.clear();
            }
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
    if (yoloResults.isNotEmpty) {
      yoloResults.clear();
    }
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
              fontSize: 7.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
