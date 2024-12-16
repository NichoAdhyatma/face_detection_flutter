import 'dart:io';
import 'dart:math';
import 'dart:developer' as dev;

import 'package:camera/camera.dart';
import 'package:face_detection/controllers/face_recognition_controller.dart';
import 'package:face_detection/main.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

var inputImageFormat =
    Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;

class BaseController extends GetxController {
  CameraController cameraController =
      CameraController(cameras.first, ResolutionPreset.high);
  FaceRecognitionController faceRecognitionController =
      FaceRecognitionController.find;

  final Map<DeviceOrientation, int> orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  final RxInt cameraIndex = 0.obs;

  @override
  void onInit() {
    _startLiveFeed();
    addFaceDetection();
    super.onInit();
  }

  void addFaceDetection() {
    cameraController.startImageStream(
      (CameraImage cameraImage) async {
        final inputImage = InputImage.fromBytes(
          bytes: cameraImage.planes[0].bytes,
          metadata: InputImageMetadata(
            size: const Size(200, 200),
            rotation: InputImageRotation.rotation0deg,
            bytesPerRow: 10,
            format: Platform.isAndroid
                ? InputImageFormat.nv21
                : InputImageFormat.bgra8888,
          ),
        );

        dev.log("${inputImage.filePath}", name: "Stream Image Path");

        faceRecognitionController.processImage(inputImage);
      },
    );
  }

  Future _startLiveFeed() async {
    final camera = cameras[cameraIndex.value];
    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await cameraController.initialize();


    update();
  }

  Future switchLiveCamera() async {
    cameraIndex.value = cameraIndex.value == 0 ? 1 : 0;

    await cameraController.dispose();
    await _startLiveFeed();

    update();
  }

  Future startPreview() async {
    await cameraController.resumePreview();

    await cameraController.initialize();

    update();
  }

  Future stopLiveFeed() async {
    await cameraController.pausePreview();

    update();
  }
}
