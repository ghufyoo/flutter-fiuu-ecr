import 'package:equatable/equatable.dart';

class UsbDeviceEntity extends Equatable {
  final int deviceId;
  final String? productName;
  final int vid;
  final int pid;

  const UsbDeviceEntity({
    required this.deviceId,
    this.productName,
    required this.vid,
    required this.pid,
  });

  @override
  List<Object?> get props => [deviceId, productName, vid, pid];
}
