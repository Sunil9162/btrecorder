import 'dart:developer';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  RxBool isLoading = false.obs;
  RxString connectingDeviceName = ''.obs;
  static HomeController get to => Get.find();
  RxList<BluetoothDevice> devices = <BluetoothDevice>[].obs;

  getPairedDevices() async {
    isLoading.value = true;
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
    );
    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        devices.add(result.device);
      }
    });
    devices.value = devices.toSet().toList();
    await Future.delayed(const Duration(seconds: 10));
    FlutterBluePlus.stopScan();
    subscription.cancel();
    log(devices.toString());
    isLoading.value = false;
  }

  void connectToDevice(BluetoothDevice device) {}
}
