import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:convert/convert.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ecr_message.dart';
import '../../domain/entities/usb_device_entity.dart';
import '../../domain/repositories/ecr_repository.dart';
import '../datasources/serial_data_source.dart';
import '../models/usb_device_model.dart';
import '../services/ecr_message_builder.dart';

class EcrRepositoryImpl implements EcrRepository {
  final SerialDataSource serialDataSource;
  final EcrMessageBuilder messageBuilder;

  EcrRepositoryImpl({
    required this.serialDataSource,
    required this.messageBuilder,
  });

  @override
  Future<Either<Failure, List<UsbDeviceEntity>>> getAvailableDevices() async {
    try {
      final devices = await serialDataSource.getAvailableDevices();
      return Right(devices.cast<UsbDeviceEntity>());
    } catch (e) {
      return Left(DeviceFailure('Failed to get available devices: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> connectToDevice(UsbDeviceEntity device) async {
    try {
      if (device is! UsbDeviceModel) {
        return Left(DeviceFailure('Invalid device type'));
      }

      final result = await serialDataSource.connectToDevice(device);
      return Right(result);
    } catch (e) {
      return Left(ConnectionFailure('Failed to connect to device: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> disconnectFromDevice() async {
    try {
      final result = await serialDataSource.disconnectFromDevice();
      return Right(result);
    } catch (e) {
      return Left(ConnectionFailure('Failed to disconnect from device: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> sendHexData(String hexData) async {
    try {
      final cleanedHex = hexData.replaceAll(RegExp(r'\s+'), '');
      final data = hex.decode(cleanedHex);
      final result = await serialDataSource.sendData(Uint8List.fromList(data));
      return Right(result);
    } catch (e) {
      return Left(DataTransmissionFailure('Failed to send hex data: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> sendEcrMessage(EcrMessage message) async {
    try {
      final formattedAmount = message.amount.padLeft(12, '0');
      final messageData = messageBuilder.constructPurchaseMessage(
        transactionId: message.transactionId,
        amount: formattedAmount,
        merchantIndex: message.merchantIndex,
      );

      final result = await serialDataSource.sendData(messageData);
      return Right(result);
    } catch (e) {
      return Left(DataTransmissionFailure('Failed to send ECR message: $e'));
    }
  }

  @override
  Stream<String> get dataStream => serialDataSource.dataStream;

  @override
  bool get isConnected => serialDataSource.isConnected;

  @override
  UsbDeviceEntity? get connectedDevice => serialDataSource.connectedDevice;
}
