// Author: ghufyoo
// ECR BLoC events

import 'package:equatable/equatable.dart';

import '../../domain/entities/ecr_message.dart';
import '../../domain/entities/usb_device_entity.dart';

abstract class EcrEvent extends Equatable {
  const EcrEvent();

  @override
  List<Object> get props => [];
}

class LoadAvailableDevices extends EcrEvent {}

class ConnectToDeviceEvent extends EcrEvent {
  final UsbDeviceEntity device;

  const ConnectToDeviceEvent(this.device);

  @override
  List<Object> get props => [device];
}

class DisconnectFromDeviceEvent extends EcrEvent {}

class SendHexDataEvent extends EcrEvent {
  final String hexData;

  const SendHexDataEvent(this.hexData);

  @override
  List<Object> get props => [hexData];
}

class SendEcrMessageEvent extends EcrEvent {
  final EcrMessage message;

  const SendEcrMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}

class DataReceivedEvent extends EcrEvent {
  final String data;

  const DataReceivedEvent(this.data);

  @override
  List<Object> get props => [data];
}

class ClearLogsEvent extends EcrEvent {}
