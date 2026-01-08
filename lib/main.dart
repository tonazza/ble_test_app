import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart' as logger_pkg;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'r1.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
final FlutterReactiveBle _ble = FlutterReactiveBle();

var logPrint = logger_pkg.Logger(printer: logger_pkg.PrettyPrinter());

Timer cicloLettura = Timer(const Duration(seconds: 0), () {});
String r1DeviceId = "";
const intervalloLetturaSecondi = 5;
R1Device dispositivoR1 = R1Device();






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
  dynamic connessioneBLE;

  

  void _startReading() async {
    await Permission.bluetoothConnect.request();
    dispositivoR1.connectToDevice();
    cicloLettura = Timer.periodic(
                const Duration(seconds: intervalloLetturaSecondi),
                (Timer t) => dispositivoR1.readData(),
      );
  }

  void _stopReading() {
    cicloLettura.cancel();
    dispositivoR1.disconnectFromDevice();
  }

  void _findR1Device() async {

    // verifico se il bluetooth è attivato
    if ((_ble.status == BleStatus.poweredOff) || (_ble.status == BleStatus.unauthorized)) {
      showDialog(context: context, builder: (context)=> AlertDialog(
        title: const Text("Bluetooth Disabled"),
        content: const Text("Please enable Bluetooth to proceed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ], 
      ));
      return;
    } 


    // verifico la piattaforma e richiedo i permessi necessari
    if (Platform.isAndroid) {
      AndroidDeviceInfo systemInfo = await deviceInfo.androidInfo;
      final sdkVersion = systemInfo.version.sdkInt;
      logPrint.i('Running on ${systemInfo.model} - Android SDK version: $sdkVersion');
      if (sdkVersion<=30) {
        if (await Geolocator.isLocationServiceEnabled() == false) {
          showDialog(context: context, builder: (context)=> AlertDialog(
        title: const Text("Position Disabled"),
        content: const Text("Please enable Position services to proceed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ], 
      ));
      return;
        }
        await Permission.locationWhenInUse.request();
        await Permission.bluetooth.request();
      } else {
        await Permission.bluetoothScan.request();
        await Permission.bluetoothConnect.request();
      }
    } else if (Platform.isIOS) {
      IosDeviceInfo systemInfo = await deviceInfo.iosInfo;
      logPrint.i('Running on ${systemInfo.utsname.machine} - iOS version: ${systemInfo.systemVersion} ');
      await Permission.bluetoothScan.request();
    }
    
    dispositivoR1.findDevice();
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
              onPressed: () => _startReading(),
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
