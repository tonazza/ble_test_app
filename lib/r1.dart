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
  bool dispositivoTrovato = false; //flag che indica se il dispositivo è stato trovato

  double temperatura = 0.0; //°C
  double umidita = 0.0; //%RH
  int co2 = 0; //ppm
  int voc = 0; // indice SENSIRION
  int aqiTotale = 0;
  int aqiHT = 0;    
  int aqiCO2 = 0;
  int aqiVOC = 0;
  String firmwareVersion = "";

  dynamic connessioneBLE; //oggetto che contiene la connessione BLE al dispositivo
  dynamic qualifiedCharList; //lista delle caratteristiche GATT del dispositivo
  final flutterReactiveBle = FlutterReactiveBle();

  // *********** COSTANTI DEL DISPOSITIVO R1 ***********

  //costante di timeout per la connessione BLE
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
        //logPrint.i("Characteristic: ${qualChar.characteristicId} - Value: $response",);
        parseData(qualChar.characteristicId.toString(), response);
      }
      logPrint.i("Temperatura = $temperatura °C, Umidità = $umidita %RH, CO2 = $co2 ppm");
      logPrint.i("VOC = $voc, AQI Totale = $aqiTotale, Firmware = $firmwareVersion");
      logPrint.i("AQI HT = $aqiHT, AQI CO2 = $aqiCO2, AQI VOC = $aqiVOC ");
    }
  }

  void parseData(String id, List<int> readingValue) {
    switch (id.toUpperCase()) {
      case "2A6E": // Temperature
        temperatura = (readingValue[0] + readingValue[1]*256) / 100;
        break;
      case "2A6F": // Humidity
        umidita = (readingValue[0] + readingValue[1]*256) / 100;
        break;
      case "2B8C": // CO2
        co2 = readingValue[0] + readingValue[1]*256;
        break;
      case "2BE7": // VOC
        voc = readingValue[0] + readingValue[1]*256;
        break;
      case "FF01": // AQI Total
        aqiTotale = readingValue[0];  
        break;
      case "FF02": // AQI HT
        aqiHT = readingValue[0];
        break;
      case "FF03": // AQI CO2
        aqiCO2 = readingValue[0];
        break;  
      case "FF04": // AQI VOC
        aqiVOC = readingValue[0];
        break;
      case "FFAA": // Firmware Version
        firmwareVersion = "v${readingValue[1]}.${readingValue[0]}";
        break;
      // Add cases for each characteristic UUID to parse the data accordingly
      default:
        logPrint.w("Unknown characteristic UUID: $id");
    }

    // Implement data parsing logic specific to R1 device
  }


}
