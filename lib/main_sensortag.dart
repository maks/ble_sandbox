import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SensorTag',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'SensorTag'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var scanResultsSubscription;
  FlutterBlue flutterBlue = FlutterBlue.instance;

  Status status = Status.Idle;

  BluetoothDevice _connectedDevice;
  BluetoothService _accelService;

  List<int> _accel;
  bool _listening = false;

  int _buttonState = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}: $status'),
      ),
      body: Center(
        child: (_connectedDevice == null)
            ? CircularProgressIndicator()
            : ConnectedDevice(
                device: _connectedDevice,
                disconnectDevice: _disconnectDevice,
                accel: _accel,
                stopAccel: () {
                  _disableAccel(_accelService);
                },
                buttonState: _buttonState,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanForDevices(flutterBlue),
        tooltip: 'Scan',
        child: Icon(Icons.search),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    scanResultsSubscription.cancel();
  }

  void _scanForDevices(FlutterBlue flutterBlue) {
    // Start scanning
    setState(() {
      status = Status.Scanning;
    });
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    scanResultsSubscription = flutterBlue.scanResults.listen((results) async {
      // do something with scan results
      for (ScanResult r in results) {
        print('${r.device.name ?? r.device.id} found! rssi: ${r.rssi}');
        if (r.device.name.toLowerCase().startsWith('sensortag')) {
          if (_connectedDevice == null) {
            // Stop scanning
            flutterBlue.stopScan();

            _connectDevice(r.device);
            setState(() {
              status = Status.Connected;
            });
          } else {
            print('already connected to ${r.device.name}');
          }
        }
      }
    });
    if (status == Status.Scanning) {
      // Stop scanning
      flutterBlue.stopScan();
    }
  }

  void _connectDevice(final BluetoothDevice device) async {
    // Connect to the device
    await device.connect();
    _discoverServices(device);
    setState(() {
      _connectedDevice = device;
    });
  }

  void _disconnectDevice(final BluetoothDevice device) async {
    // Disconnect from device
    await device.disconnect();
    setState(() {
      _connectedDevice = null;
      _listening = false;
      _accelService = null;

      status = Status.Disconnected;
    });
  }

  void _discoverServices(final BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();

    await Future.forEach(services, (service) async {
      print('got service: ${service.uuid}');
      if (service.uuid.toString() == 'f000aa10-0451-4000-b000-000000000000') {
        _accelService = service;

        if (!_listening) {
          await _enableAccel(service);
        }
      }

      if (service.uuid.toString() == '0000ffe0-0000-1000-8000-00805f9b34fb') {
        print('got button Service');
        service.characteristics.forEach((c) async {
          if (c.uuid.toString() == '0000ffe1-0000-1000-8000-00805f9b34fb') {
            c.value.listen((event) {
              setState(() {
                _buttonState = event.isNotEmpty ? event[0] : 0;
              });
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
    // final charPeriod =
    //     getForId(accelService, 'f000aa13-0451-4000-b000-000000000000');

    // Set accelerometer period to 500 ms, as units is in 10ms.
    // charPeriod.write([50]);
    // Set accelerometer configuration to ON.
    charConfig.write([1], withoutResponse: true);

    charData.value.listen((event) {
      setState(() {
        _accel = event;
        _listening = true;
      });
    });
    final r = await charData.setNotifyValue(true);
  }

  void _disableAccel(BluetoothService accelService) async {
    final charData =
        getForId(accelService, 'f000aa11-0451-4000-b000-000000000000');
    await charData.setNotifyValue(false);
    final charConfig =
        getForId(accelService, 'f000aa12-0451-4000-b000-000000000000');
    await charConfig.write([0], withoutResponse: true);
  }

  BluetoothCharacteristic getForId(BluetoothService service, String uuid) =>
      service.characteristics.where((c) => c.uuid.toString() == uuid).first;
}

class ButtonState extends StatelessWidget {
  final state;

  bool get leftDown => state == 2 || state == 3;
  bool get rightDown => state == 1 || state == 3;

  const ButtonState({Key key, this.state = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: null,
          child: Text('Left', style: Theme.of(context).textTheme.headline5),
          style: TextButton.styleFrom(
              backgroundColor: leftDown ? Colors.amber : Colors.grey),
        ),
        Container(width: 30),
        TextButton(
          onPressed: null,
          child: Text('Right', style: Theme.of(context).textTheme.headline5),
          style: TextButton.styleFrom(
              backgroundColor: rightDown ? Colors.amber : Colors.grey),
        ),
      ],
    );
  }
}

class ConnectedDevice extends StatelessWidget {
  final BluetoothDevice device;
  final List<BluetoothService> services;
  final Function(BluetoothDevice) disconnectDevice;
  final List<int> accel;
  final Function stopAccel;
  final int buttonState;

  const ConnectedDevice({
    Key key,
    this.device,
    this.services,
    this.disconnectDevice,
    this.accel,
    @required this.stopAccel,
    this.buttonState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Connected Device:..',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        Text('Accel data: ${accel ?? "none"}'),
        TextButton(
          onPressed: stopAccel,
          child: Text('Stop Accel Data'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BTDeviceName(
              device: device,
            ),
            TextButton(
              onPressed: () => disconnectDevice(device),
              child: Text('Disconnect'),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: ButtonState(state: buttonState),
        ),
        Container(
          height: 250,
          child: ListView.separated(
            itemBuilder: (context, index) {
              return Text('${services[index]}');
            },
            itemCount: services?.length ?? 0,
            separatorBuilder: (BuildContext context, int index) => Divider(
              thickness: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class BTDeviceName extends StatelessWidget {
  final BluetoothDevice device;

  const BTDeviceName({Key key, this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${device?.name?.isEmpty ?? false ? 'Unknown' : device?.name}',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Text('${device?.id}'),
        ],
      ),
    );
  }
}

enum Status { Idle, Scanning, Connected, Disconnected }
