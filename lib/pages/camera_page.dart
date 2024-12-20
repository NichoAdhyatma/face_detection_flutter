import 'package:camera/camera.dart';
import 'package:face_detection/widgets/face_overlay.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/camera_setup_controller.dart';

class CameraWidget extends GetView<CameraSetupController> {
  const CameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GetBuilder<CameraSetupController>(builder: (controller) {
      if (!controller.cameraController.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      final isPreviewPaused = controller.cameraController.value.isPreviewPaused;

      return SingleChildScrollView(
        child: Column(
          children: [
            // Camera preview or paused message
            isPreviewPaused
                ? SizedBox(
                    height: size.height * 0.7,
                    child: const Center(
                      child: Text(
                        "Video Paused",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : SizedBox(
                    width: size.width,
                    height: size.height * 0.7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller.cameraController),
                        const FaceOverlayWidget(),
                      ],
                    ),
                  ),

            const SizedBox(
              height: 20,
            ),
            // Control buttons
            SizedBox(
              height: 50,
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8.0),
                  children: [
                    ElevatedButton(
                      onPressed: controller.enrollFace,
                      child: const Text('Enroll Face'),
                    ),
                    ElevatedButton(
                      onPressed: controller.verifyFace,
                      child: const Text('Verify Face'),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.switchLiveCamera,
                      icon: const Icon(Icons.switch_camera),
                      label: const Text("Switch"),
                    ),
                    ElevatedButton.icon(
                      onPressed: isPreviewPaused
                          ? controller.startPreview
                          : controller.stopLiveFeed,
                      icon: Icon(
                          isPreviewPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(isPreviewPaused ? "Start" : "Stop"),
                    ),
                  ]),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  controller.enrolledFaceImage != null
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          child: Image.file(
                            controller.enrolledFaceImage!,
                            width: 150,
                            fit: BoxFit.fill,
                          ),
                        )
                      : Container(),
                  controller.verificationImage != null
                      ? Container(
                          margin: const EdgeInsets.all(8),
                          child: Image.file(
                            controller.verificationImage!,
                            width: 150,
                            fit: BoxFit.fill,
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
            controller.isMatchFace != null
                ? Text(controller.isMatchFace! ? "Matched" : "Not Matched")
                : Container(),
          ],
        ),
      );
    });
  }
}
