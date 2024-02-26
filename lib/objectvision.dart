import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:tadeeflutter/services/yolovideo.dart';
import 'package:floating/floating.dart';

class ObjectVision extends StatefulWidget {
  const ObjectVision({super.key});

  @override
  State<ObjectVision> createState() => _ObjectVisionState();
}

class _ObjectVisionState extends State<ObjectVision>
    with WidgetsBindingObserver {
  late FlutterVision vision;
  final floating = Floating();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YoloVideo(vision: vision),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsFlutterBinding.ensureInitialized();

    vision = FlutterVision();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.inactive) {
      floating.enable(aspectRatio: const Rational.square());
    }
  }

  Future<void> enablePip(BuildContext context) async {
    const rational = Rational.vertical();
    final screenSize =
        MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio;
    final height = screenSize.width ~/ rational.aspectRatio;

    final status = await floating.enable(
      aspectRatio: rational,
      sourceRectHint: Rectangle<int>(
        0,
        (screenSize.height ~/ 2) - (height ~/ 2),
        screenSize.width.toInt(),
        height,
      ),
    );
    debugPrint('PiP enabled? $status');
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    floating.dispose();
    await vision.closeYoloModel();
  }
}
