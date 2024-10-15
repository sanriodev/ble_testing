import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// UUID and Charactereistics for TWA Reader
final Uuid serviceUUID = Uuid.parse("5A44C004-4112-4274-880E-CD9B3DAEDF8E");
final Uuid characteristicsUUID =
    Uuid.parse("43C29EDF-2F0A-4C43-AA22-489D169EC752");

// BLE Distance
const int rssiDISTANCE = -85;

const List<String> deviceNames = ["EMAT BLE", "TWN4 BLE"];
