import 'dart:io';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:face_detection/controllers/face_recognition_controller.dart';
import 'package:face_detection/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';

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

  bool isProcessing = false;

  File? enrolledFaceImage;
  Face? enrolledFace;

  // Threshold untuk menentukan kecocokan wajah
  final double SIMILARITY_THRESHOLD = 0.7;

  final RxInt cameraIndex = 0.obs;

  @override
  void onInit() {
    _startLiveFeed();
    super.onInit();
  }

  Future _startLiveFeed() async {
    final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await cameraController.initialize();

    cameraController.startImageStream(_processCameraImage);

    update();
  }

  void _processCameraImage(CameraImage image) async {
    final InputImage inputImage = _convertToInputImage(
      image,
      cameraController.description,
    );

    dev.log("Input Image: ${inputImage.toString()}");

    await faceRecognitionController.processImage(inputImage);
  }

  InputImage _convertToInputImage(
      CameraImage cameraImage, CameraDescription cameraDescription) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    InputImageRotation rotation;
    switch (cameraDescription.sensorOrientation) {
      case 0:
        rotation = InputImageRotation.rotation0deg;
        break;
      case 90:
        rotation = InputImageRotation.rotation90deg;
        break;
      case 180:
        rotation = InputImageRotation.rotation180deg;
        break;
      case 270:
        rotation = InputImageRotation.rotation270deg;
        break;
      default:
        rotation = InputImageRotation.rotation0deg;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(cameraImage.width.toDouble(), cameraImage.height.toDouble()),
        rotation: rotation,
        format: Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      ),
    );
  }

  Future switchLiveCamera() async {
    cameraIndex.value = cameraIndex.value == 0 ? 1 : 0;

    await cameraController.dispose();

    await _startLiveFeed();

    update();
  }

  Future startPreview() async {
    await cameraController.resumePreview();

    await cameraController.dispose();

    _startLiveFeed();

    update();
  }

  Future stopLiveFeed() async {
    await cameraController.pausePreview();

    await cameraController.stopImageStream();

    update();
  }

  Future<void> enrollFace() async {
    if (isProcessing) return;
    isProcessing = true;

    update();

    dev.log("Start to enroll face");

    Get.snackbar("Start", "Start to enroll face");

    try {
      // Capture gambar
      final XFile image = await cameraController.takePicture();

      // Simpan gambar
      final directory = await getApplicationDocumentsDirectory();
      final savedImage =
          await File(image.path).copy('${directory.path}/${DateTime.now()}.png');

      // Deteksi wajah pada gambar
      final inputImage = InputImage.fromFilePath(savedImage.path);
      final faces =
          await faceRecognitionController.faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        Get.snackbar('Error', 'No face detected. Please try again.');
        return;
      }

      if (faces.length > 1) {
        Get.snackbar('Error',
            'Multiple faces detected. Please try again with only one face.');
        return;
      }

      // Simpan wajah yang terdeteksi
      enrolledFaceImage = savedImage;
      enrolledFace = faces.first;

      dev.log('Enrolled Face: $enrolledFace, dir: $enrolledFaceImage');
      Get.dialog(
        AlertDialog(
          title: const Text('Success'),
          content: const Text('Face enrolled successfully!'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to enroll face: $e');
    } finally {
      isProcessing = false;
      update();
    }
  }

  Future<bool> verifyFace() async {
    if (isProcessing || enrolledFace == null) return false;
    isProcessing = true;
    update();

    try {
      // Capture gambar untuk verifikasi
      final image = await cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faces =
          await faceRecognitionController.faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        Get.snackbar('Error', 'No face detected. Please try again.');
        return false;
      }

      if (faces.length > 1) {
        Get.snackbar('Error',
            'Multiple faces detected. Please try again with only one face.');
        return false;
      }

      final detectedFace = faces.first;

      // Verifikasi wajah berdasarkan berbagai faktor
      final bool isMatch = await _compareFaces(enrolledFace!, detectedFace);

      if (isMatch) {
        dev.log('Face verification successful!');
        Get.snackbar('Success', 'Face verification successful!');
      } else {
        dev.log('Face verification failed');
        Get.snackbar('Error', 'Face verification failed. Please try again.');
      }

      return isMatch;
    } catch (e) {
      Get.snackbar('Error', 'Failed to verify face: $e');
      return false;
    } finally {
      isProcessing = false;
      update();
    }
  }

  Future<bool> _compareFaces(Face enrolledFace, Face detectedFace) async {
    // Hitung similarity score berdasarkan berbagai faktor
    double similarityScore = 0.0;

    // 1. Bandingkan landmark wajah
    if (enrolledFace.landmarks.isNotEmpty &&
        detectedFace.landmarks.isNotEmpty) {
      similarityScore += _compareLandmarks(enrolledFace, detectedFace) * 0.4;
    }

    // 2. Bandingkan rotasi wajah
    similarityScore += _compareRotation(enrolledFace, detectedFace) * 0.2;

    // 3. Bandingkan ukuran wajah relatif
    similarityScore += _compareSize(enrolledFace, detectedFace) * 0.2;

    // 4. Bandingkan ekspresi wajah (jika tersedia)
    if (enrolledFace.smilingProbability != null &&
        detectedFace.smilingProbability != null) {
      similarityScore += (1.0 -
              (enrolledFace.smilingProbability! -
                      detectedFace.smilingProbability!)
                  .abs()) *
          0.2;
    }

    return similarityScore >= SIMILARITY_THRESHOLD;
  }

  double _compareLandmarks(Face face1, Face face2) {
    var differences = 0.0;
    var totalPoints = 0;

    face1.landmarks.forEach((type, point1) {
      if (face2.landmarks.containsKey(type)) {
        final point2 = face2.landmarks[type]!;
        differences += sqrt(
          pow(point1!.position.x - point2.position.x, 2) +
              pow(
                point1.position.y - point2.position.y,
                2,
              ),
        );
        totalPoints++;
      }
    });

    if (totalPoints == 0) return 0.0;
    return 1.0 - (differences / totalPoints / 100); // Normalisasi
  }

  double _compareRotation(Face face1, Face face2) {
    final rotationDiff =
        (face1.headEulerAngleY! - face2.headEulerAngleY!.toInt()).abs();

    dev.log('Rotation Diff: $rotationDiff');

    return 1.0 - (rotationDiff / 360.0); // Normalisasi ke 0-1
  }

  double _compareSize(Face face1, Face face2) {
    // Bandingkan rasio ukuran wajah
    final ratio1 = face1.boundingBox.width / face1.boundingBox.height;
    final ratio2 = face2.boundingBox.width / face2.boundingBox.height;
    return 1.0 - (ratio1 - ratio2).abs();
  }
}
