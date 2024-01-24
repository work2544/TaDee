import 'package:flutter/material.dart';
import 'package:tadeeflutter/models/screen_params.dart';
import 'package:tadeeflutter/ui/detector_widget.dart';

/// [DetectorView] stacks [DetectorWidget]
class DetectorView extends StatelessWidget {
  const DetectorView({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenParams.screenSize = MediaQuery.sizeOf(context);
    return Scaffold(
      key: GlobalKey(),
      backgroundColor: Colors.black,
      appBar: AppBar(
        
      ),
      body: const DetectorWidget(),
    );
  }
}
