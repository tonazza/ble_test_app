import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logger/logger.dart' as logger_pkg;

/*
*****************************************************************************
  Definizioni specifiche del sensore di qualità dell'aria R1 di Aerauliqa
*****************************************************************************
*/

var logPrint = logger_pkg.Logger(printer: logger_pkg.PrettyPrinter());

class R1Device {
  // variabili del dispositivo R1
  String deviceId = ""; //MAC Address del dispositivo
  bool dispositivoTrovato =
      false; //flag che indica se il dispositivo è stato trovato
  dynamic
  connessioneBLE; //oggetto che contiene la connessione BLE al dispositivo
  dynamic qualifiedCharList; //lista delle caratteristiche GATT del dispositivo

  final flutterReactiveBle = FlutterReactiveBle();

  static const bleConnectionTimeout = 5; //timeout di connessione in secondi

  // ID BLE GATT dle servizio di Environmental Sensing
  final Uuid uuidService = Uuid.parse("181A");

  // nome BLE del dispositivo R1
  final String deviceName = "AIRQURE_R1";

  // mappa degli UUID delle caratteristiche GATT esposte dal dispositivo R1
  //con testo descrittivo come chiave
  final charUuidMap = <String, Uuid>{
    "Temperature": Uuid.parse("2A6E"),
    "Humidity": Uuid.parse("2A6F"),
    "CO2": Uuid.parse("2B8C"),
    "VOC": Uuid.parse("2BE7"),
    "AQI Total": Uuid.parse("FF01"),
    "AQI HT": Uuid.parse("FF02"),
    "AQI CO2": Uuid.parse("FF03"),
    "AQI VOC": Uuid.parse("FF04"),
    "Firmware Version": Uuid.parse("FFAA"),
  };

  // funzione che genera la lista delle caratteristiche qualificate del dispositivo R1
  // da passare al metodo di lettura. viene eseguita nel momento in cui
  // si conosce l'ID del dispositivo (MAC Address)
  List<QualifiedCharacteristic> setQualifiedCharList(String idDispositivo) {
    List<QualifiedCharacteristic> charList = [];
    for (Uuid charUuid in charUuidMap.values) {
      charList.add(
        QualifiedCharacteristic(
          serviceId: uuidService,
          characteristicId: charUuid,
          deviceId: idDispositivo,
        ),
      );
    }
    return charList;
  }

  // funzione di inizializzazione del dispositivo R1
  void initializeR1(String idDispositivo) {
    dispositivoTrovato = true;
    deviceId = idDispositivo;
    qualifiedCharList = setQualifiedCharList(idDispositivo);
  }

  // funzione di terminazione del dispositivo R1
  void disposeR1() {
    dispositivoTrovato = false;
    qualifiedCharList = null;
    deviceId = "";
  }

  //procedura che esegue la scansione BLE per trovare il dispositivo R1
  void findDevice() {
    connessioneBLE = flutterReactiveBle
        .scanForDevices(
          withServices: [uuidService],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          (device) {
            logPrint.i("Found device: ${device.name}, id: ${device.id}");
            if (device.name == deviceName) {
              connessioneBLE.cancel();
              logPrint.i("R1 device found: ${device.name}, id: ${device.id}");
              initializeR1(device.id);
            }
            //code for handling results
          },
          onError: (error, stackTrace) {
            logPrint.e("Error while scanning for devices: $error");
            disposeR1();
            //code for handling error, optionally inspect stackTrace
          },
        );
  }

  //procedura che esegue la connessione al dispositivo R1
  void connectToDevice() {
    connessioneBLE = flutterReactiveBle
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: bleConnectionTimeout),
        )
        .listen(
          (connectionState) async {
            if (connectionState.connectionState ==
                DeviceConnectionState.connected) {
              logPrint.i("Device $deviceId connected successfully.");
            }
          },
          onError: (error) {
            logPrint.e("Error connecting to device $deviceId: $error");
            // Handle a possible error
          },
        );
  }

  //procedura che esegue la disconnessione dal dispositivo R1
  void disconnectFromDevice() {
    if (connessioneBLE != null) {
      connessioneBLE.cancel();
      logPrint.i("Disconnected from device $deviceId.");
    }
  }

  //funzione che legge i dati dalle caratteristiche GATT del dispositivo R1
  void readData() async {
    if (connessioneBLE != null) {
      for (QualifiedCharacteristic qualChar in qualifiedCharList) {
        final response = await flutterReactiveBle.readCharacteristic(qualChar);
        logPrint.i(
          "Characteristic: ${qualChar.characteristicId} - Value: $response  ",
        );
      }
    }
  }
}
