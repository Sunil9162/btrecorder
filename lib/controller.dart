import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:get/get.dart';

enum DeviceType { advertiser, browser }

class HomeController extends GetxController {
  RxBool isLoading = false.obs;
  RxString connectingDeviceName = ''.obs;
  static HomeController get to => Get.find();
  RxList<Device> devices = RxList<Device>();
  RxList<Device> connectedDevices = RxList<Device>();
  Rxn<DeviceType> deviceType = Rxn<DeviceType>();
  final nearbyService = NearbyService();

  StreamSubscription? subscription;
  StreamSubscription? receivedDataSubscription;
  RxMap receivedData = RxMap();
 
  
 

  initConnect() async {
    String devInfo = "";
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService.init(
      serviceType: 'mpconnect',
      deviceName: devInfo,
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          if (deviceType.value == DeviceType.browser) {
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(const Duration(microseconds: 200));
            await nearbyService.startBrowsingForPeers();
          } else {
            await nearbyService.stopAdvertisingPeer();
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(const Duration(microseconds: 200));
            await nearbyService.startAdvertisingPeer();
            await nearbyService.startBrowsingForPeers();
          }
        }
      },
    );
    subscription =
        nearbyService.stateChangedSubscription(callback: (devicesList) {
      for (var element in devicesList) {
        if (Platform.isAndroid) {
          if (element.state == SessionState.connected) {
            nearbyService.stopBrowsingForPeers();
          } else {
            nearbyService.startBrowsingForPeers();
          }
        }
        devices.clear();
        devices.addAll(devicesList);
        connectedDevices.clear();
        connectedDevices.addAll(devicesList
            .where((d) => d.state == SessionState.connected)
            .toList());
        devices.refresh();
        connectedDevices.refresh();
      }
    });
    receivedDataSubscription =
        nearbyService.dataReceivedSubscription(callback: (data) {
      receivedData.value = data as Map;
    });
  }

  onButtonClicked(Device device) {
    switch (device.state) {
      case SessionState.notConnected:
        nearbyService.invitePeer(
          deviceID: device.deviceId,
          deviceName: device.deviceName,
        );
        break;
      case SessionState.connected:
        nearbyService.disconnectPeer(deviceID: device.deviceId);
        break;
      case SessionState.connecting:
        break;
    }
  }

  int getItemCount() {
    if (deviceType.value == DeviceType.advertiser) {
      return connectedDevices.length;
    } else {
      return devices.length;
    }
  }

  sendData(String message) {
    final device = connectedDevices.first;
    nearbyService.sendMessage(
      device.deviceId,
      message,
    );
  }

  disconnect() {
    subscription?.cancel();
    receivedDataSubscription?.cancel();
    nearbyService.stopAdvertisingPeer();
    nearbyService.stopBrowsingForPeers();
    devices.clear();
    connectedDevices.clear();
  }
}
