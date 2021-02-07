import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Sandbox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'BLE Sandbox Home Page'),
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

  BluetoothDevice _connectedDevice;
  List<BluetoothDevice> _scannedDevices = [];
  List<BluetoothService> _services = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: (_connectedDevice == null)
            ? Scanlist(
                devices: _scannedDevices,
                connectDevice: _connectDevice,
              )
            : ConnectedDevice(
                device: _connectedDevice,
                disconnectDevice: _disconnectDevice,
                services: _services,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanForDevices(flutterBlue),
        tooltip: 'Increment',
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
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    scanResultsSubscription = flutterBlue.scanResults.listen((results) {
      // do something with scan results
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
        _addDeviceTolist(r.device);
      }
    });
    // Stop scanning
    flutterBlue.stopScan();
  }

  void _addDeviceTolist(final BluetoothDevice device) {
    if (!_scannedDevices.contains(device)) {
      setState(() {
        _scannedDevices.add(device);
      });
    }
  }

  void _connectDevice(final BluetoothDevice device) async {
    // Connect to the device
    await device.connect();
    _discoverServices(device);
    setState(() {
      _connectedDevice = device;
      _scannedDevices.remove(device);
    });
  }

  void _disconnectDevice(final BluetoothDevice device) async {
    // Disconnect from device
    device.disconnect();
    setState(() {
      _scannedDevices.add(device);
      _connectedDevice = null;
      _services.clear();
    });
  }

  void _discoverServices(final BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      setState(() {
        _services.add(service);
      });
    });
  }
}

class Scanlist extends StatelessWidget {
  final List<BluetoothDevice> devices;
  final Function(BluetoothDevice) connectDevice;

  const Scanlist({Key key, this.devices, this.connectDevice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 800,
      child: ListView.builder(
        itemBuilder: (context, index) {
          final device = devices[index];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BTDeviceName(
                device: device,
              ),
              TextButton(
                onPressed: () => connectDevice(device),
                child: Text('Connect'),
              )
            ],
          );
        },
        itemCount: devices.length,
      ),
    );
  }
}

class ConnectedDevice extends StatelessWidget {
  final BluetoothDevice device;
  final List<BluetoothService> services;
  final Function(BluetoothDevice) disconnectDevice;

  const ConnectedDevice(
      {Key key, this.device, this.disconnectDevice, this.services})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 800,
      child: Column(
        children: [
          Text(
            'Connected Device:',
            style: TextStyle(
              fontSize: 16,
            ),
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
          Container(
            height: 450,
            child: ListView.separated(
              itemBuilder: (context, index) {
                return BTServiceCard(services[index]);
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

class BTServiceCard extends StatelessWidget {
  final BluetoothService service;
  BTServiceCard(
    this.service,
  );

  @override
  Widget build(BuildContext context) {
    final chars = service.characteristics;
    return Column(
      children: [
        Text('Service: ${service.uuid}'),
        Container(
          height: 200,
          child: ListView.builder(
            itemBuilder: (context, index) {
              final char = chars[index];
              return Column(
                children: [
                  Text('uuid: ${char.uuid}'),
                  Text('${char.properties}'),
                ],
              );
            },
            itemCount: chars.length,
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
