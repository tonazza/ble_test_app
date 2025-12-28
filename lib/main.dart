import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logger/logger.dart' as logger_pkg;
import 'package:permission_handler/permission_handler.dart';

var logPrint = logger_pkg.Logger(
  printer: logger_pkg.PrettyPrinter(),
);

void main() {
  runApp(const MyApp());
}

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
  final Uuid serviceId = Uuid.parse("181A"); // Example: Environmental Sensing Service
  final flutterReactiveBle = FlutterReactiveBle();
  dynamic connessioneBLE;

  void _connectToDevice(String deviceId) async {
    await Permission.bluetoothConnect.request();
    connessioneBLE = flutterReactiveBle.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 5),
    ).listen((connectionState) {
      logPrint.i("Connection state for device $deviceId: $connectionState");
      // Handle connection state changes
    }, onError: (error) {
      logPrint.e("Error connecting to device $deviceId: $error");
      // Handle a possible error
    });
  }


  void _findBLEDevices() async {
      await Permission.bluetoothScan.request();

      connessioneBLE = flutterReactiveBle
          .scanForDevices(
            withServices: [serviceId],
            scanMode: ScanMode.lowLatency,
          )
          .listen(
            (device) {
              logPrint.i("Found device: ${device.name}, id: ${device.id}"); 
              if(device.name =="AIRQURE_R1"){
                connessioneBLE.cancel();
                _connectToDevice(device.id);
                logPrint.i("Target device found: ${device.name}, id: ${device.id}"); 
              } 
              //code for handling results
            },
            onError: (error, stackTrace) {
              logPrint.e("Error while scanning for devices: $error");
              //code for handling error, optionally inspect stackTrace
            }
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
              onPressed: _findBLEDevices,
              child: const Text('Find BLE Devices'),
            ),
          ],
        ),
      ),
    );
  }
}
