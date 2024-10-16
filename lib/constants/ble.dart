// UUID and Charactereistics for TWA Reader
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

final Guid serviceUUID =
    Guid.fromString("5A44C004-4112-4274-880E-CD9B3DAEDF8E");
final Guid characteristicsUUID =
    Guid.fromString("43C29EDF-2F0A-4C43-AA22-489D169EC752");
final Guid weightCharacteristicsUUID =
    Guid.fromString('43C29EDF-2F0A-4C43-AA22-489D169EC754');
// BLE Distance
const int rssiDISTANCE = -85;

const List<String> deviceNames = ["EMAT BLE", "EMAT BLE BC"];
