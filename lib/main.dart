import 'package:camera/camera.dart';
import 'package:face_detection/controllers/base_controller.dart';
import 'package:face_detection/controllers/face_recognition_controller.dart';
import 'package:face_detection/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  Get.put(BaseController());

  Get.put(FaceRecognitionController());


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}


