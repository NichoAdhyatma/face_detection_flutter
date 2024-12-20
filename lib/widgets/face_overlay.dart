import 'package:face_detection/controllers/camera_setup_controller.dart';
import 'package:face_detection/controllers/face_recognition_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FacePainter extends CustomPainter {
  final List<Rect> boundingBoxes;
  final Size imageSize;

  FacePainter({required this.boundingBoxes, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final previewRatio = size.width / size.height;
    final imageRatio = imageSize.width / imageSize.height;

    double scaleX = size.width / imageSize.width;
    double scaleY = size.height / imageSize.height;

    if (imageRatio > previewRatio) {
      scaleY = scaleX;
    } else {
      scaleX = scaleY;
    }

    final double offsetX = (size.width - imageSize.width * scaleX) / 2;
    final double offsetY = (size.height - imageSize.height * scaleY) / 2;

    canvas.save();
    canvas.translate(size.width, 0);
    canvas.scale(-1, 1);

    for (final Rect boundingBox in boundingBoxes) {
      final Rect transformedRect = Rect.fromLTRB(
        offsetX + boundingBox.left * scaleX,
        offsetY + boundingBox.top * scaleY,
        offsetX + boundingBox.right * scaleX,
        offsetY + boundingBox.bottom * scaleY,
      );

      canvas.drawRect(transformedRect, paint);

      canvas.drawCircle(
        transformedRect.center,
        5,
        Paint()..color = Colors.blue,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.boundingBoxes != boundingBoxes;
  }
}

class FaceOverlayWidget extends GetView<CameraSetupController> {
  const FaceOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    FaceRecognitionController faceRecognitionController =
        Get.find<FaceRecognitionController>();
    return GetBuilder<FaceRecognitionController>(
      builder: (_) {
        if (controller.cameraController.value.previewSize == null) {
          return const SizedBox.shrink();
        }

        final previewSize = controller.cameraController.value.previewSize!;

        return CustomPaint(
          painter: FacePainter(
            boundingBoxes: faceRecognitionController.boundingBoxes,
            imageSize: Size(previewSize.height, previewSize.width),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
