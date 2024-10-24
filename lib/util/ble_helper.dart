import 'package:ble_testing/constants/ble.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

bool checkDevice(DiscoveredDevice device, Map devices, Map barriers) {
  if (device.rssi < rssiDISTANCE) {
    return false;
  }
  if (!deviceNames.contains(device.name)) {
    return false;
  }
  if (devices.containsKey(device.id)) {
    return false;
  }
  if (barriers.containsKey(device.id)) {
    return false;
  }
  return true;
}

Future<Characteristic> sendString(
    FlutterReactiveBle flutterReactiveBle, DiscoveredDevice device) async {
  await flutterReactiveBle.discoverAllServices(device.id);
  List<Service> services =
      await flutterReactiveBle.getDiscoveredServices(device.id);

  List<Characteristic> allCharacters = [];
  List<Characteristic> writeableCharacter = [];

  allCharacters = services
      .firstWhere((element) => element.id == serviceUUID)
      .characteristics;

  for (var element in allCharacters) {
    if (element.id == characteristicsUUID) {
      writeableCharacter.add(element);
    }
  }
  return writeableCharacter.first;
}

Map<String, String?> getManufacturerDataFromBroadcast(DiscoveredDevice device) {
  String dataString =
      String.fromCharCodes(device.manufacturerData).split("R").last;
  String terminalID = dataString.substring(0, 8);
  String terminalStatus = dataString.substring(8, 9);
  String? connectedCitizen;
  if (dataString.length > 9) connectedCitizen = dataString.substring(9, 13);
  return {
    "terminalID": terminalID,
    "terminalStatus": terminalStatus,
    "connectedCitizen": connectedCitizen
  };
}
