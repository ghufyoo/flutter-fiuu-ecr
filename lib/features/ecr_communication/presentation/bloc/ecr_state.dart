import 'package:equatable/equatable.dart';

import '../../domain/entities/communication_log.dart';
import '../../domain/entities/usb_device_entity.dart';

abstract class EcrState extends Equatable {
  const EcrState();

  @override
  List<Object?> get props => [];
}

class EcrInitial extends EcrState {}

class EcrLoading extends EcrState {}

class EcrDevicesLoaded extends EcrState {
  final List<UsbDeviceEntity> devices;

  const EcrDevicesLoaded(this.devices);

  @override
  List<Object> get props => [devices];
}

class EcrDeviceConnected extends EcrState {
  final UsbDeviceEntity device;
  final List<UsbDeviceEntity> availableDevices;
  final List<CommunicationLog> logs;

  const EcrDeviceConnected({
    required this.device,
    required this.availableDevices,
    required this.logs,
  });

  @override
  List<Object> get props => [device, availableDevices, logs];

  EcrDeviceConnected copyWith({
    UsbDeviceEntity? device,
    List<UsbDeviceEntity>? availableDevices,
    List<CommunicationLog>? logs,
  }) {
    return EcrDeviceConnected(
      device: device ?? this.device,
      availableDevices: availableDevices ?? this.availableDevices,
      logs: logs ?? this.logs,
    );
  }
}

class EcrError extends EcrState {
  final String message;

  const EcrError(this.message);

  @override
  List<Object> get props => [message];
}
