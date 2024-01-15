import 'package:btrecorder/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
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
        actions: [
          IconButton(
            onPressed: () {
              controller.deviceType.value = null;
              controller.disconnect();
            },
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.deviceType.value != DeviceType.browser)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      controller.deviceType.value = DeviceType.advertiser;
                      controller.initConnect();
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              if (controller.deviceType.value != DeviceType.advertiser)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      controller.deviceType.value = DeviceType.browser;
                      controller.initConnect();
                    },
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Recieve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
      body: Obx(() {
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: controller.getItemCount(),
          itemBuilder: (context, index) {
            final device = controller.deviceType.value == DeviceType.advertiser
                ? controller.connectedDevices[index]
                : controller.devices[index];
            return Container(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device.deviceName),
                              Text(
                                getStateName(device.state),
                                style: TextStyle(
                                    color: getStateColor(device.state)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Request connect
                      GestureDetector(
                        onTap: () => controller.onButtonClicked(device),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          height: 35,
                          width: 100,
                          color: getButtonColor(device.state),
                          child: Center(
                            child: Text(
                              getButtonStateName(device.state),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  const Divider(
                    height: 1,
                    color: Colors.grey,
                  )
                ],
              ),
            );
          },
        );
      }),
    );
  }

  String getStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return "disconnected";
      case SessionState.connecting:
        return "waiting";
      default:
        return "connected";
    }
  }

  String getButtonStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return "Connect";
      default:
        return "Disconnect";
    }
  }

  Color getStateColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return Colors.black;
      case SessionState.connecting:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Color getButtonColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return Colors.green;
      default:
        return Colors.red;
    }
  }
}
