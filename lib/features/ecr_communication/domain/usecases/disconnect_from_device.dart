import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ecr_repository.dart';

class DisconnectFromDevice implements UseCase<bool, NoParams> {
  final EcrRepository repository;

  DisconnectFromDevice(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.disconnectFromDevice();
  }
}
