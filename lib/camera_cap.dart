import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:math';

class CameraCapt extends StatefulWidget {
  @override
  _CameraCapt createState() => _CameraCapt();
}

class _CameraCapt extends State<CameraCapt> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  late File _image;
  late Future<void> _initControllerFuture;
  final List<double> _gyroscopeValues = [0, 0, 0];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  late final path;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initCamera();

    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues[0] = event.x;
            _gyroscopeValues[1] = event.y;
            _gyroscopeValues[2] = event.z;
          });
        },
      ),
    );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras![0], ResolutionPreset.medium);
    _controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  double _getAngle() {
    double x = _gyroscopeValues[0];
    double y = _gyroscopeValues[1];
    double z = _gyroscopeValues[2];
    double angle = atan2(x, y) * (180 / pi);
    return angle;
  }

  Future<String?> _takePicture() async {
    try {
      final image = await _controller!.takePicture();
      File image_ = File(image.path);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now()}.jpg';
      final filePath = '${appDir.path}/$fileName';
      GallerySaver.saveImage(image_.path);
      // final savedImage = await image_.copy(filePath);
      // await ImageGallerySaver.saveFile(file.path);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    final gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();

    final size = MediaQuery.of(context).size;
    final deviceRatio = (size.width) / (size.height - 50);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera_alt),
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: deviceRatio,
              child: CameraPreview(_controller!),
            ),
            Positioned(
              child: Container(
                width: MediaQuery.of(context).size.width,
                // height: MediaQuery.of(context).size.height,
                color: Colors.black.withOpacity(0.5),
                padding: EdgeInsets.all(10),
                child: Text(
                  'Angle ${_getAngle()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
