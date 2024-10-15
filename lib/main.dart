import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ble_testing/constants/ble.dart';
import 'package:ble_testing/util/ble_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

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
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  // late StreamSubscription<ConnectionStateUpdate> currentConnectionStream;
  DiscoveredDevice? bleDeviceFound;
  Stopwatch connectionStopWatch = Stopwatch();
  Map<String, Map<Future<String>, DiscoveredDevice>> barriers = {};
  Map<String, Map<Future<String>, DiscoveredDevice>> devices = {};
  bool isConnected = false;
  late StreamSubscription<ConnectionStateUpdate> currentConnectionStream;

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
    final stopWatchBroadCast = Stopwatch()..start();
    _scanStream = flutterReactiveBle.scanForDevices(
        //withServices was an empty array we try it iwth the serviceUUID
        withServices: [],
        requireLocationServicesEnabled: true,
        scanMode: ScanMode.lowLatency).listen((device) {
      if (checkDevice(device, devices, barriers)) {
        // print("new Device found: ${device.name}");
        if (device.name == "EMAT BLE") {
          // print(
          //     "Device found:${device.name} in ${stopwatch.elapsedMilliseconds} ms");
          stopwatch.reset();
          setState(() {
            bleDeviceFound = device;
          });
        } else {
          // print(
          //     "Device found: ${device.name} in ${stopWatchBroadCast.elapsedMilliseconds} ms");
          stopWatchBroadCast.reset();
        }
      }
    });
  }

  void connect(DiscoveredDevice device, bool retryOnFailed) {
    // Stops Scan Stream
    _stopScan();
    connectionStopWatch.start();
    // Tries to establish connection to device
    currentConnectionStream = flutterReactiveBle
        .connectToDevice(
            id: device.id,
            servicesWithCharacteristicsToDiscover: {
              serviceUUID: [characteristicsUUID, weightCharacteristicsUUID]
            },
            connectionTimeout: const Duration(seconds: 2))
        .listen((event) async {
      print(event.connectionState);
      switch (event.connectionState) {
        case DeviceConnectionState.connected:
          _writeCharacter(device, !isConnected);

          break;
        case DeviceConnectionState.disconnected:
          connectionStopWatch.stop();
          connectionStopWatch.reset();
          if (retryOnFailed) {
            currentConnectionStream.cancel();
            await Future.delayed(
              const Duration(milliseconds: 200),
            );
            connect(device, false);
          }

          // await Future.delayed(const Duration(milliseconds: 500));
          break;
        default:
      }
    });
  }

  void _writeCharacter(DiscoveredDevice device, bool connection) async {
    // Gets Character where to write
    Characteristic character = await sendString(flutterReactiveBle, device);

    // connection to Characteristic
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceUUID,
        characteristicId: character.id,
        deviceId: device.id);

    // await Future.delayed(const Duration(milliseconds: 200));
    //Writes Characteristic

    try {
      await flutterReactiveBle.writeCharacteristicWithoutResponse(
          characteristic,
          value: utf8.encode("Hello World"));
    } on GenericFailure<WriteCharacteristicFailure> {
      _writeCharacter(device, connection);
    }

    setState(() {
      connectionStopWatch.stop();
      isConnected = connection;
    });

    if (Platform.isIOS) {
      await Future.delayed(const Duration(milliseconds: 700));
    }

    // await currentConnectionStream.cancel();
  }

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
