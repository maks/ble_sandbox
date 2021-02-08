import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';

enum Status { Idle, Scanning, Connected, Disconnected }

class SensorTag extends ChangeNotifier {
  Status __status = Status.Idle;
  bool __listening = false;
  int __buttonState = 0;
  List<int> __accel;

  FlutterBlue _flutterBlue;
  BluetoothDevice __connectedDevice;
  BluetoothService _accelService;
  StreamSubscription _scanResultsSubscription;

  get name => __connectedDevice?.name;

  get id => __connectedDevice?.id;

  set _status(Status status) {
    __status = status;
    notifyListeners();
  }

  Status get status => __status;

  set _listening(bool l) {
    __listening = l;
    notifyListeners();
  }

  bool get listening => __listening;

  set _buttonState(int b) {
    __buttonState = b;
    notifyListeners();
  }

  int get buttonState => __buttonState;

  set _accel(List<int> a) {
    __accel = a;
    notifyListeners();
  }

  List<int> get accel => __accel;

  set _connectedDevice(BluetoothDevice d) {
    __connectedDevice = d;
    notifyListeners();
  }

  bool get connected => __connectedDevice != null;

  @override
  void dispose() {
    super.dispose();
    _scanResultsSubscription?.cancel();
  }

  void scanForDevice() {
    _flutterBlue = FlutterBlue.instance;
    // Start scanning
    _status = Status.Scanning;
    _flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    _scanResultsSubscription = _flutterBlue.scanResults.listen((results) async {
      // do something with scan results
      for (ScanResult r in results) {
        print('${r.device.name ?? r.device.id} found! rssi: ${r.rssi}');
        if (r.device.name.toLowerCase().startsWith('sensortag')) {
          if (!connected) {
            // Stop scanning
            _flutterBlue.stopScan();
            _connectDevice(r.device);
            _status = Status.Connected;
          } else {
            print('already connected to ${r.device.name}');
          }
        }
      }
    });
    if (status == Status.Scanning) {
      // Stop scanning
      _flutterBlue.stopScan();
    }
  }

  void _connectDevice(final BluetoothDevice device) async {
    // Connect to the device
    await device.connect();
    _discoverServices(device);
    _connectedDevice = device;
  }

  void disconnectDevice() async {
    if (!connected) {
      return;
    }

    // Disconnect from device
    await __connectedDevice.disconnect();

    _connectedDevice = null;
    _listening = false;
    _accelService = null;
    _status = Status.Disconnected;
  }

  void _discoverServices(final BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    await Future.forEach(services, (service) async {
      print('got service: ${service.uuid}');
      if (service.uuid.toString() == 'f000aa10-0451-4000-b000-000000000000') {
        _accelService = service;

        if (!listening) {
          await _enableAccel(service);
        }
      }

      if (service.uuid.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb') {
        print('got button Service');
        service.characteristics.forEach((c) async {
          if (c.uuid.toString() == '0000ffe1-0000-1000-8000-00805f9b34fb') {
            c.value.listen((event) {
              _buttonState = event.isNotEmpty ? event[0] : 0;
            });
            await c.setNotifyValue(true);
          }
        });
      }
    });
  }

  Future<void> _enableAccel(BluetoothService accelService) async {
    final charData =
        getForId(accelService, 'f000aa11-0451-4000-b000-000000000000');
    final charConfig =
        getForId(accelService, 'f000aa12-0451-4000-b000-000000000000');
    final charPeriod =
        getForId(accelService, 'f000aa13-0451-4000-b000-000000000000');

    // Set accelerometer period to 500 ms, as units is in 10ms.
    await charPeriod.write([50]);
    // Set accelerometer configuration to ON.
    await charConfig.write([1], withoutResponse: true);

    charData.value.listen((event) {
      _accel = event;
      _listening = true;
    });
    await charData.setNotifyValue(true);
  }

  void disableAccel() async {
    final charData =
        getForId(_accelService, 'f000aa11-0451-4000-b000-000000000000');
    await charData.setNotifyValue(false);
    final charConfig =
        getForId(_accelService, 'f000aa12-0451-4000-b000-000000000000');
    await charConfig.write([0], withoutResponse: true);
  }

  BluetoothCharacteristic getForId(BluetoothService service, String uuid) =>
      service.characteristics.where((c) => c.uuid.toString() == uuid).first;
}
