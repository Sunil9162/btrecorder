import 'dart:developer';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:btrecorder/controller.dart';
import 'package:camera/camera.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final homeController = Get.put(HomeController());

  late List<CameraDescription> cameras;
  late CameraController controller;
  late Stream batteryStream;
  final battery = Battery();
  RxBool isRecording = false.obs;
  RxBool isLoading = true.obs;
  RxBool isFlashOn = false.obs;
  RxInt batteryLevel = 0.obs;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      initCamera();
    }
    batteryStream = Stream.periodic(
      const Duration(seconds: 5),
    );

    batteryStream.listen((event) async {
      batteryLevel.value = await battery.batteryLevel;
      log("Battery level is ${batteryLevel.value}");
      if (batteryLevel.value <= 5) {
        stopRecording();
        log("Video Stopped Recorded Succesfully ");
      }
    });
    homeController.receivedData.listen((p0) {
      final data = p0;
      if (data['message'] == "StopRecording") {
        stopRecording();
      } else if (data['message'] == "StartRecording") {
        startRecording();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  stopRecording() async {
    if (isRecording.value) {
      Get.dialog(const Center(
        child: CircularProgressIndicator(),
      ));
      final file = await controller.stopVideoRecording();
      // Save File to Local Storage
      final filepath = await FileSaver.instance.saveFile(
        name:
            'BTRecorder_${homeController.deviceType.value == DeviceType.advertiser ? "left" : "right"}_${DateTime.now().millisecondsSinceEpoch}.mp4',
        file: File(file.path),
        mimeType: MimeType.other,
      );
      Get.back();
      log("Saved to $filepath");
      isRecording.value = false;
    }
  }

  startRecording() {
    if (controller.value.isInitialized) {
      if (controller.value.isRecordingVideo) {
        controller.stopVideoRecording();
        isRecording.value = false;
      } else {
        controller.startVideoRecording();
        isRecording.value = true;
      }
    }
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final firstCamera = cameras.first;
      // Initialize the first camera
      _initCameraController(firstCamera);
    }
  }

  void _initCameraController(CameraDescription cameraDescription) {
    isLoading.value = true;
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
    )..initialize().then((_) {
        if (!mounted) {
          return;
        }
        isLoading.value = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        title: const Text(
          'BT Recorder',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Get.to(() => const SettingsPage());
            },
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Obx(
        () {
          if (isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final scale = 1 /
              (controller.value.aspectRatio *
                  MediaQuery.of(context).size.aspectRatio);
          return Stack(
            children: [
              Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: CameraPreview(controller),
              ),
              Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      child: Container(
                        color: Colors.black.withOpacity(0.0),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final Directory directory =
                                  await getApplicationDocumentsDirectory();

                              final List<FileSystemEntity> files =
                                  directory.listSync();
                              List<String> recordedData = [];
                              for (final FileSystemEntity file in files) {
                                recordedData.addIf(
                                  file.path.endsWith(".mp4"),
                                  file.path,
                                );
                              }
                              log("Recorded Paths are $recordedData");
                              for (var rec in recordedData) {
                                log("is mp4 contiains ${rec.contains(".mp4")}");
                              }
                            },
                            icon: Icon(
                              isFlashOn.value
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (isRecording.value) {
                                await stopRecording();
                                homeController.sendData(
                                  "StopRecording",
                                );
                              } else {
                                await startRecording();
                                homeController.sendData(
                                  "StartRecording",
                                );
                              }
                            },
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Obx(
                                () => Center(
                                  child: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isRecording.value
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if (controller.value.isInitialized) {
                                final newCamera = cameras.firstWhere(
                                    (element) =>
                                        element.lensDirection !=
                                        controller.description.lensDirection);
                                _initCameraController(newCamera);
                              }
                            },
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
