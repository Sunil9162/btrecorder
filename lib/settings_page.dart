import 'package:btrecorder/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final controller = HomeController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Recorder'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Bluetooth Devices",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(
                  () => IconButton(
                    onPressed: () {
                      if (controller.isLoading.value) {
                        return;
                      }
                      controller.getPairedDevices();
                    },
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: Colors.blue,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.devices.length,
                itemBuilder: (context, index) {
                  final device = controller.devices[index];
                  return ListTile(
                    onTap: () {
                      controller.connectToDevice(device);
                    },
                    title: Text(
                      device.platformName.isEmpty
                          ? device.remoteId.toString()
                          : device.platformName,
                    ),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: StreamBuilder<BluetoothConnectionState>(
                      stream: device.connectionState,
                      initialData: BluetoothConnectionState.disconnected,
                      builder: (c, snapshot) {
                        if (snapshot.data ==
                            BluetoothConnectionState.connected) {
                          return const Icon(
                            Icons.bluetooth_connected,
                            color: Colors.green,
                          );
                        }
                        if (controller.connectingDeviceName.value ==
                            device.platformName) {
                          return const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        }
                        return const Icon(
                          Icons.bluetooth,
                          color: Colors.grey,
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ],
        ).paddingAll(15),
      ),
    );
  }
}
