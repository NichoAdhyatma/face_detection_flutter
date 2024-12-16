import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_detection/controllers/base_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../main.dart';

class CameraWidget extends GetView<BaseController> {
  const CameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BaseController>(builder: (_) {
      if (!controller.cameraController.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          Expanded(
            child: !controller.cameraController.value.isPreviewPaused
                ? controller.cameraController.buildPreview()
                : const Center(
                    child: Text("Video Paused"),
                  ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  controller.switchLiveCamera();
                },
                child: const Text("Switch"),
              ),
              ElevatedButton(
                onPressed: () async {
                  controller.cameraController.value.isPreviewPaused
                      ? controller.startPreview()
                      : controller.stopLiveFeed();
                },
                child: controller.cameraController.value.isPreviewPaused
                    ? Text("Start")
                    : Text("Stop"),
              ),
            ],
          ),
        ],
      );
    });
  }
}
