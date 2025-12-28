import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/*
*****************************************************************************
  Definizioni specifiche del sensore di qualità dell'aria R1 di Aerauliqa
*****************************************************************************
*/


// ID BLE GATT dle servizio di Environmental Sensing
final Uuid uuidService = Uuid.parse("181A");

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

// lista delle caratteristiche qualificate del dispositivo R1
// da passare al metodo di lettura
List<QualifiedCharacteristic> qualifiedCharList(String idDispositivo) {
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


