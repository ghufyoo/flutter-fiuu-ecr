import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/usb_device_entity.dart';
import '../repositories/ecr_repository.dart';

class ConnectToDevice implements UseCase<bool, ConnectToDeviceParams> {
  final EcrRepository repository;

  ConnectToDevice(this.repository);

  @override
  Future<Either<Failure, bool>> call(ConnectToDeviceParams params) async {
    return await repository.connectToDevice(params.device);
  }
}

class ConnectToDeviceParams extends Equatable {
  final UsbDeviceEntity device;

  const ConnectToDeviceParams({required this.device});

  @override
  List<Object> get props => [device];
}
