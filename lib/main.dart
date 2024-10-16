import 'dart:async';
import 'package:ble_testing/constants/ble.dart';
import 'package:ble_testing/util/ble_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final flutterBlue = FlutterBluePlus();
  late StreamSubscription<List<ScanResult>> _scanStream;
  // late StreamSubscription<ConnectionStateUpdate> currentConnectionStream;
  BluetoothDevice? bleDeviceFound;
  Stopwatch connectionStopWatch = Stopwatch();
  Map<String, Map<Future<String>, BluetoothDevice>> barriers = {};
  Map<String, Map<Future<String>, BluetoothDevice>> devices = {};
  bool isConnected = false;
  late StreamSubscription<BluetoothConnectionState> currentConnectionStream;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void reassemble() {
    _startScan();
    super.reassemble();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  void _stopScan() async {
    await _scanStream.cancel();
  }

  void _startScan() async {
    final stopwatch = Stopwatch()..start();
    _scanStream = FlutterBluePlus.onScanResults.listen((device) async {
      List<BluetoothDevice> validDevices =
          await checkDevice(device, devices, barriers);
      if (validDevices.isNotEmpty) {
        // print("new Device found: ${device.name}");
        for (var item in validDevices) {
          if (item.platformName == "EMAT BLE") {
            // print(
            //     "Device found:${device.name} in ${stopwatch.elapsedMilliseconds} ms");
            stopwatch.reset();
            setState(() {
              bleDeviceFound = item;
            });
          } else {
            // var test = getManufacturerDataFromBroadcast(device);
            // if (test["connectedCitizen"] != null ||
            //     test['terminalStatus'] == 'L') {
            //   bleDeviceFound = null;
            // }
            // stopWatchBroadCast.reset();
            // print(test);
          }
        }
      }
    });
    await FlutterBluePlus.startScan(
      withServices: [], // match any of the specified services
      withNames: deviceNames, // *or* any of the specified names
    );
  }

  void connect(BluetoothDevice device, bool retryOnFailed) async {
    // Stops Scan Stream
    _stopScan();
    connectionStopWatch.start();
    // Tries to establish connection to device
    currentConnectionStream = device.connectionState.listen((event) {
      print(event.name);
      switch (event) {
        case BluetoothConnectionState.connected:
          // _writeCharacter(device, !isConnected);
          setState(() {
            connectionStopWatch.stop();
            isConnected = true;
          });
          break;
        case BluetoothConnectionState.disconnected:
          connectionStopWatch.stop();
          connectionStopWatch.reset();
          if (retryOnFailed) {
            currentConnectionStream.cancel();
            connect(device, false);
          }

          // await Future.delayed(const Duration(milliseconds: 500));
          break;
        default:
      }
    });
    device.connect(timeout: const Duration(seconds: 1), autoConnect: false);
  }

  // void _writeCharacter(BluetoothDevice device, bool connection) async {
  //   // Gets Character where to write
  //   BluetoothCharacteristic character = await sendString(flutterBlue, device);

  //   // connection to Characteristic
  //   final characteristic = BluetoothCharacteristic(
  //       serviceUuid: serviceUUID,
  //       characteristicUuid: character.characteristicUuid,
  //       remoteId: device.remoteId);

  //   // await Future.delayed(const Duration(milliseconds: 200));
  //   //Writes Characteristic

  //   try {
  //     await FlutterBluePlus.(
  //       characteristic,
  //       value: utf8.encode("AuthorizedCard"),
  //     );
  //   } on GenericFailure<WriteCharacteristicFailure> {
  //     _writeCharacter(device, connection);
  //   }

  //   setState(() {
  //     connectionStopWatch.stop();
  //     isConnected = connection;
  //   });

  //   if (Platform.isIOS) {
  //     await Future.delayed(const Duration(milliseconds: 700));
  //   }

  //   // await currentConnectionStream.cancel();
  // }

  void disconnect() {
    currentConnectionStream.cancel();
    setState(() {
      isConnected = false;
      connectionStopWatch.reset();
    });
    _startScan();
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Visibility(
                visible: bleDeviceFound != null && !isConnected,
                child: ElevatedButton(
                    onPressed: () {
                      connect(bleDeviceFound!, true);
                    },
                    child: const Text("Connect"))),
            Visibility(
                visible: isConnected,
                child: ElevatedButton(
                    onPressed: () {
                      disconnect();
                    },
                    child: const Text("Disconnect"))),
            Visibility(
              visible: isConnected,
              child: Text(
                'Connecting took ${connectionStopWatch.elapsedMilliseconds} ms',
              ),
            ),
            Visibility(
              visible: !isConnected,
              child: const Text(
                'disconnected...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
