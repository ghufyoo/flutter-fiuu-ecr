import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/usb_serial.dart';
import 'package:convert/convert.dart';

import '../models/usb_device_model.dart';

abstract class SerialDataSource {
  Future<List<UsbDeviceModel>> getAvailableDevices();
  Future<bool> connectToDevice(UsbDeviceModel device);
  Future<bool> disconnectFromDevice();
  Future<bool> sendData(Uint8List data);
  Stream<String> get dataStream;
  bool get isConnected;
  UsbDeviceModel? get connectedDevice;
}

class SerialDataSourceImpl implements SerialDataSource {
  UsbPort? _port;
  UsbDeviceModel? _connectedDevice;
  StreamSubscription<Uint8List>? _subscription;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  bool get isConnected => _port != null && _connectedDevice != null;

  @override
  UsbDeviceModel? get connectedDevice => _connectedDevice;

  @override
  Future<List<UsbDeviceModel>> getAvailableDevices() async {
    try {
      final devices = await UsbSerial.listDevices();
      return devices
          .map((device) => UsbDeviceModel.fromUsbDevice(device))
          .toList();
    } catch (e) {
      throw Exception('Failed to get available devices: $e');
    }
  }

  @override
  Future<bool> connectToDevice(UsbDeviceModel device) async {
    try {
      _port = await device.usbDevice.create();
      final openResult = await _port!.open();

      if (!openResult) {
        _port = null;
        throw Exception('Could not open device');
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _subscription = _port!.inputStream?.listen(
        (data) {
          final hexString = hex.encode(data);
          _dataController.add(hexString);
        },
        onError: (error) {
          _dataController.addError(error);
        },
      );

      _connectedDevice = device;
      return true;
    } catch (e) {
      await _cleanup();
      throw Exception('Failed to connect to device: $e');
    }
  }

  @override
  Future<bool> disconnectFromDevice() async {
    try {
      await _cleanup();
      return true;
    } catch (e) {
      throw Exception('Failed to disconnect from device: $e');
    }
  }

  @override
  Future<bool> sendData(Uint8List data) async {
    if (_port == null) {
      throw Exception('No device connected');
    }

    try {
      await _port!.write(data);
      return true;
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  Future<void> _cleanup() async {
    await _subscription?.cancel();
    await _port?.close();
    _port = null;
    _connectedDevice = null;
    _subscription = null;
  }

  void dispose() {
    _cleanup();
    _dataController.close();
  }
}
