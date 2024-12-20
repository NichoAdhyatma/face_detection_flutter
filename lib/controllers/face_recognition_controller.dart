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
  static FaceRecognitionController find = Get.put<FaceRecognitionController>(FaceRecognitionController());
  final RxList<Rect> boundingBoxes = <Rect>[].obs;
  final double SIMILARITY_THRESHOLD = 0.7;

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

      face.contours.forEach((FaceContourType contour, FaceContour? type) {
        dev.log('Contour: $contour, Type: ${type?.points}');
      });
    }

    update();
  }

  Future<bool> compareFaces(Face enrolledFace, Face detectedFace) async {
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
