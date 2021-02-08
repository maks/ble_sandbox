import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';

import 'devices/sensortag.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FlutterBlue.instance.setLogLevel(LogLevel.critical);
    return ChangeNotifierProvider(
      create: (context) => SensorTag(),
      child: MaterialApp(
        title: 'SensorTag',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'SensorTag'),
      ),
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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final sensorTag = context.watch<SensorTag>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}: ${sensorTag.status}'),
      ),
      body: Center(
        child: (!sensorTag.connected)
            ? CircularProgressIndicator()
            : ConnectedDevice(
                deviceName: sensorTag.name,
                deviceId: sensorTag.id.toString(),
                disconnectDevice: sensorTag.disconnectDevice,
                accel: sensorTag.accel,
                stopAccel: () {
                  sensorTag.disableAccel();
                },
                buttonState: sensorTag.buttonState,
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => sensorTag.scanForDevice(),
        tooltip: 'Scan',
        child: Icon(Icons.search),
      ),
    );
  }
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
  final String deviceName;
  final String deviceId;
  final List<BluetoothService> services;
  final Function() disconnectDevice;
  final List<int> accel;
  final Function stopAccel;
  final int buttonState;

  const ConnectedDevice({
    Key key,
    this.deviceName,
    this.services,
    this.disconnectDevice,
    this.accel,
    @required this.stopAccel,
    this.buttonState,
    this.deviceId,
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
              name: deviceName,
              id: deviceId,
            ),
            TextButton(
              onPressed: () => disconnectDevice(),
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
  final String name;
  final String id;

  const BTDeviceName({Key key, this.name, this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${name?.isEmpty ?? false ? 'Unknown' : name}',
              style: TextStyle(fontSize: 18),
            ),
          ),
          Text('$id'),
        ],
      ),
    );
  }
}
