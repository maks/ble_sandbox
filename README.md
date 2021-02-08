# BLE Sandbox

This project serves as a sandbox for Flutter apps that interact with various BLE devices.


## TI SensorTag CC2541

### Flutter app

`lib\main_sensortag.dart` is a basic Flutter app that connects to a TI CC2541 SensorTag device over BLE.
For now it just displays accelerometer sensor data and state of the 2 push buttons on the device, as well as
allowing the accelerometer sensor to be deactivated.

This demonstrates all the basic types of interactions over BLE with the sensortag.

https://www.ti.com/tool/CC2541SENSORTAG-RD

### Docs

https://web.archive.org/web/20171218051940/https://processors.wiki.ti.com/index.php/SensorTag_User_Guide

[Full BLE attributes spec sheet](file:///home/maks/Downloads/BLE_SensorTag_GATT_Server.pdf)


[This example code with the BLE services and characteristics was very helpful to get me started.](https://github.com/evothings/evothings-examples/blob/master/examples/ble-ti-sensortag-cc2541-demo/app.js)
It was especially useful in understanding how to turn on/off the accelerometer sensor. 

## Espruino Puck.js

[Docs for using BLE with the Puck.](https://www.espruino.com/About+Bluetooth+LE)