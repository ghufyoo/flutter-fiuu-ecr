import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/usb_device_entity.dart';
import '../repositories/ecr_repository.dart';

class GetAvailableDevices implements UseCase<List<UsbDeviceEntity>, NoParams> {
  final EcrRepository repository;

  GetAvailableDevices(this.repository);

  @override
  Future<Either<Failure, List<UsbDeviceEntity>>> call(NoParams params) async {
    return await repository.getAvailableDevices();
  }
}
