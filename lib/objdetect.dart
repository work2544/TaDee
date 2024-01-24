import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'package:tadeeflutter/services/objectdetect.dart';

class ObjectDetect extends StatefulWidget {
  const ObjectDetect({super.key});

  @override
  State<ObjectDetect> createState() => _ObjectDetectState();
}

class _ObjectDetectState extends State<ObjectDetect> {
  final imagePicker = ImagePicker();

  ObjectDetection? objectDetection;
  @override
  void initState() {
    super.initState();
    objectDetection = ObjectDetection();
  }

  Uint8List? image;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image detection'),
        backgroundColor: Colors.black.withOpacity(0.5),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: (image != null) ? Image.memory(image!) : Container(),
              ),
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (Platform.isAndroid || Platform.isIOS)
                    IconButton(
                      onPressed: () async {
                        final result = await imagePicker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (result != null) {
                          image = objectDetection!.analyseImage(result.path);
                          setState(() {});
                        }
                      },
                      icon: const Icon(
                        Icons.camera,
                        size: 64,
                      ),
                    ),
                  IconButton(
                    onPressed: () async {
                      log('message',name: 'pick image button');
                      final result = await imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (result != null) {
                        log('pick image');
                        image = objectDetection!.analyseImage(result.path);
                        setState(() {});
                      }
                    },
                    icon: const Icon(
                      Icons.photo,
                      size: 64,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
