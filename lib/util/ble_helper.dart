import 'package:ble_testing/constants/ble.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

Future<List<BluetoothDevice>> checkDevice(
    List<ScanResult> device, Map devices, Map barriers) async {
  List<BluetoothDevice> result = <BluetoothDevice>[];
  for (var item in device) {
    if (
        // await item.device.readRssi() >= rssiDISTANCE &&
        deviceNames.contains(item.device.platformName) &&
            !devices.containsKey(item.device.remoteId) &&
            !barriers.containsKey(item.device.remoteId)) {
      result.add(item.device);
    }
  }
  return result;
}

Future<BluetoothCharacteristic> sendString(
    FlutterBluePlus flutterBlue, BluetoothDevice device) async {
  List<BluetoothService> services = await device.discoverServices();

  List<BluetoothCharacteristic> allCharacters = [];
  List<BluetoothCharacteristic> writeableCharacter = [];

  allCharacters = services
      .firstWhere((element) => element.serviceUuid == serviceUUID)
      .characteristics;

  for (var element in allCharacters) {
    if (element.characteristicUuid == characteristicsUUID) {
      writeableCharacter.add(element);
    }
  }
  return writeableCharacter.first;
}

// Map<String, String?> getManufacturerDataFromBroadcast(BluetoothDevice device) {
//   String dataString =
//       String.fromCharCodes(device.).split("R").last;
//   String terminalID = dataString.substring(0, 8);
//   String terminalStatus = dataString.substring(8, 9);
//   String? connectedCitizen;
//   if (dataString.length > 9) connectedCitizen = dataString.substring(9, 13);
//   return {
//     "terminalID": terminalID,
//     "terminalStatus": terminalStatus,
//     "connectedCitizen": connectedCitizen
//   };
// }
