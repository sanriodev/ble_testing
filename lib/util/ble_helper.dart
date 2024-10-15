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
