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
  final RxList<Rect> boundingBoxes = <Rect>[].obs;

  @override
  void dispose() {
    faceDetector.close();

    super.dispose();
  }

  Future<void> processImage(InputImage inputImage) async {

    final faces = await faceDetector.processImage(inputImage);

    boundingBoxes.clear();

    dev.log("Faces: $faces");

    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;


      dev.log('Bounding Box: $boundingBox');

      boundingBoxes.add(face.boundingBox);

      final double? rotX = face.headEulerAngleX;
      final double? rotY = face.headEulerAngleY;
      final double? rotZ = face.headEulerAngleZ;

      dev.log('rotX: $rotX, rotY: $rotY, rotZ: $rotZ');

      if (face.smilingProbability != null) {
        final double? smileProb = face.smilingProbability;
        dev.log('Smile Probability: $smileProb');
      }

      if (face.leftEyeOpenProbability != null) {
        final double? leftEyeOpenProb = face.leftEyeOpenProbability;
        dev.log('Left Eye Open Probability: $leftEyeOpenProb');
      }

      if (face.trackingId != null) {
        final int? id = face.trackingId;
        dev.log('Tracking ID: $id');
      }
    }

    update();
  }
}
