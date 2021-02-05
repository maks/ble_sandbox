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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Connected Device:',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            if (_connectedDevice != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BTDeviceName(
                    device: _connectedDevice,
                  ),
                  TextButton(
                    onPressed: () => _disconnectDevice(_connectedDevice),
                    child: Text('Disconnect'),
                  )
                ],
              ),
            Divider(
              height: 16,
              thickness: 4,
              color: Colors.amberAccent,
            ),
            Container(
              height: 400,
              child: ListView.builder(
                itemBuilder: (context, index) {
                  final device = _scannedDevices[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BTDeviceName(
                        device: device,
                      ),
                      TextButton(
                        onPressed: () => _connectDevice(device),
                        child: Text('Connect'),
                      )
                    ],
                  );
                },
                itemCount: _scannedDevices.length,
              ),
            ),
          ],
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
    });
  }

  void _discoverServices(final BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      // do something with service
    });
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
              '${device.name.isEmpty ? 'Unknown' : device.name}',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Text('${device.id}'),
        ],
      ),
    );
  }
}
