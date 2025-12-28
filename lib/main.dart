import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logger/logger.dart' as logger_pkg;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'r1.dart';

var logPrint = logger_pkg.Logger(printer: logger_pkg.PrettyPrinter());

Timer cicloLettura = Timer(const Duration(seconds: 0), () {});
String r1DeviceId = "";
const intervalloLetturaSecondi = 5;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MyHomePage(title: 'BLE test home page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  dynamic connessioneBLE;

  void _readData(String deviceId) async {
    if (connessioneBLE != null) {
      for (QualifiedCharacteristic qualChar in qualifiedCharList(deviceId)) {
        final response = await flutterReactiveBle.readCharacteristic(qualChar);
        logPrint.i(
          "Characteristic: ${qualChar.characteristicId} - Value: $response  ",
        );
      }
    }
  }

  void _connectToDevice(String deviceId) async {
    await Permission.bluetoothConnect.request();
    connessioneBLE = flutterReactiveBle
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 5),
        )
        .listen(
          (connectionState) async {
            if (connectionState.connectionState ==
                DeviceConnectionState.connected) {
              logPrint.i(
                "Device $deviceId connected successfully. Starting data read cycle.",
              );
              cicloLettura = Timer.periodic(
                const Duration(seconds: intervalloLetturaSecondi),
                (Timer t) => _readData(deviceId),
              );
              _readData(deviceId);
            }
          },
          onError: (error) {
            logPrint.e("Error connecting to device $deviceId: $error");
            // Handle a possible error
          },
        );
  }

  void _stopReading() {
    cicloLettura.cancel();
    if (connessioneBLE != null) {
      connessioneBLE.cancel();
      logPrint.i("Disconnected from device.");
    }
  }

  void _findR1Device() async {
    await Permission.bluetoothScan.request();

    connessioneBLE = flutterReactiveBle
        .scanForDevices(
          withServices: [uuidService],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            logPrint.i("Found device: ${device.name}, id: ${device.id}");
            if (device.name == "AIRQURE_R1") {
              connessioneBLE.cancel();
              logPrint.i("R1 device found: ${device.name}, id: ${device.id}");
              r1DeviceId = device.id;
            }
            //code for handling results
          },
          onError: (error, stackTrace) {
            logPrint.e("Error while scanning for devices: $error");
            r1DeviceId = "";
            //code for handling error, optionally inspect stackTrace
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            ListTile(
              title: Text(
                'BLE Test App',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              subtitle: Text(
                'This is a simple app to test Bluetooth Low Energy functionality.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton(
              onPressed: () => _findR1Device(),
              child: const Text('Find R1 Device'),
            ),
            ElevatedButton(
              onPressed: () => _connectToDevice(r1DeviceId),
              child: const Text('Start Reading from R1'),
            ),
            ElevatedButton(
              onPressed: _stopReading,
              child: const Text('Stop reading from R1'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
