import 'package:camera/camera.dart';
import 'package:face_detection/widgets/face_overlay.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/base_controller.dart';

class CameraWidget extends GetView<BaseController> {
  const CameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GetBuilder<BaseController>(builder: (controller) {
      if (!controller.cameraController.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      final isPreviewPaused = controller.cameraController.value.isPreviewPaused;

      return Column(
        children: [
          // Camera preview or paused message
          Expanded(
            child: isPreviewPaused
                ? const Center(
                    child: Text(
                      "Video Paused",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : Stack(
              fit: StackFit.expand,
                    children: [
                      CameraPreview(controller.cameraController),
                      const FaceOverlayWidget(),
                    ],
                  ),
          ),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.enrollFace,
                    child: const Text('Enroll Face'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.verifyFace,
                    child: const Text('Verify Face'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.switchLiveCamera,
                    icon: const Icon(Icons.switch_camera),
                    label: const Text("Switch"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isPreviewPaused
                        ? controller.startPreview
                        : controller.stopLiveFeed,
                    icon: Icon(isPreviewPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(isPreviewPaused ? "Start" : "Stop"),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
