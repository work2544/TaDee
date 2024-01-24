import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter/material.dart';
import 'package:tadeeflutter/services/yolovideo.dart';



class ObjectVision extends StatefulWidget {
  const ObjectVision({super.key});

  @override
  State<ObjectVision> createState() => _ObjectVisionState();
}

class _ObjectVisionState extends State<ObjectVision> {
  late FlutterVision vision;
  

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
  }

  @override
  void dispose() async {
    super.dispose();
    await vision.closeYoloModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YoloVideo(vision: vision),
    );
  }
}



