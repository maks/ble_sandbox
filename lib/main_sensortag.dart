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

  List<int> _accel;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _scanForDevices(flutterBlue);
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
              ),
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
    // Stop scanning
    flutterBlue.stopScan();
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
    device.disconnect();
    setState(() {
      _connectedDevice = null;
      _listening = false;
      device.disconnect();
      status = Status.Disconnected;
    });
    Future.delayed(Duration(milliseconds: 500));
    _scanForDevices(flutterBlue);
  }

  void _discoverServices(final BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      setState(() {
        if (service.uuid.toString() == 'f000aa10-0451-4000-b000-000000000000') {
          print('got Accel Service');
          service.characteristics.forEach((c) {
            print('char: ${c.uuid.toString()}');
            if (!_listening) {
              print('listening to accel');
              _enableAccel(service);

              c.value.listen((event) {
                setState(() {
                  _accel = event;
                });
              });
              _listening = true;
            }
          });
        }
      });
    });
  }

  void _enableAccel(BluetoothService accelService) {
    final charData =
        getForId(accelService, 'f000aa11-0451-4000-b000-000000000000');
    final charConfig =
        getForId(accelService, 'f000aa12-0451-4000-b000-000000000000');
    final charPeriod =
        getForId(accelService, 'f000aa13-0451-4000-b000-000000000000');
    // final charNotification =
    //     getForId(accelService, '00002902-0000-1000-8000-00805f9b34fb');

    // Set accelerometer period to 1000 ms, as units is in 10ms.
    //charPeriod.write([100]);
    // Set accelerometer configuration to ON.
    charConfig.write([1], withoutResponse: true);
    charData.setNotifyValue(true);
  }

  BluetoothCharacteristic getForId(BluetoothService service, String uuid) =>
      service.characteristics.where((c) => c.uuid.toString() == uuid).first;
}

class ConnectedDevice extends StatelessWidget {
  final BluetoothDevice device;
  final List<BluetoothService> services;
  final Function(BluetoothDevice) disconnectDevice;
  final List<int> accel;

  const ConnectedDevice(
      {Key key, this.device, this.disconnectDevice, this.services, this.accel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 800,
      child: Column(
        children: [
          Text(
            'Connected Device:..',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
          Text('Accel data: ${accel ?? "none"}'),
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
          Container(
            height: 450,
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
      ),
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
