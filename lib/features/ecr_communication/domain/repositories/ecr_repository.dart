import 'package:dartz/dartz.dart';
import 'dart:typed_data';

import '../../../../core/error/failures.dart';
import '../entities/usb_device_entity.dart';
import '../entities/ecr_message.dart';

abstract class EcrRepository {
  Future<Either<Failure, List<UsbDeviceEntity>>> getAvailableDevices();
  Future<Either<Failure, bool>> connectToDevice(UsbDeviceEntity device);
  Future<Either<Failure, bool>> disconnectFromDevice();
  Future<Either<Failure, bool>> sendHexData(String hexData);
  Future<Either<Failure, bool>> sendEcrMessage(EcrMessage message);
  Stream<String> get dataStream;
  bool get isConnected;
  UsbDeviceEntity? get connectedDevice;
}
