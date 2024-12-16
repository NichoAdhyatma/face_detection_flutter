import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

final options = FaceDetectorOptions(
  enableClassification: true,
  enableTracking: true,
  enableContours: true,
  enableLandmarks: true,
);

class FaceRecognitionController extends GetxController {
  final faceDetector = FaceDetector(options: options);
  static FaceRecognitionController find = Get.put(FaceRecognitionController());

  @override
  void dispose() {
    faceDetector.close();

    super.dispose();
  }

  void processImage(InputImage inputImage) async {
    final faces = await faceDetector.processImage(inputImage);

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;

      final double? rotX = face.headEulerAngleX;
      final double? rotY = face.headEulerAngleY;
      final double? rotZ = face.headEulerAngleZ;

      dev.log('rotX: $rotX, rotY: $rotY, rotZ: $rotZ');
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      if (leftEar != null) {
        final Point<int> leftEarPos = leftEar.position;
      }

      if (face.smilingProbability != null) {
        final double? smileProb = face.smilingProbability;
      }

      if (face.trackingId != null) {
        final int? id = face.trackingId;
      }
    }
  }
}
