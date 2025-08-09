import 'package:usb_serial/usb_serial.dart';

import '../../domain/entities/usb_device_entity.dart';

class UsbDeviceModel extends UsbDeviceEntity {
  final UsbDevice usbDevice;

  const UsbDeviceModel({
    required this.usbDevice,
    required super.deviceId,
    super.productName,
    required super.vid,
    required super.pid,
  });

  factory UsbDeviceModel.fromUsbDevice(UsbDevice device) {
    return UsbDeviceModel(
      usbDevice: device,
      deviceId: device.deviceId ?? 0,
      productName: device.productName,
      vid: device.vid ?? 0,
      pid: device.pid ?? 0,
    );
  }
}
