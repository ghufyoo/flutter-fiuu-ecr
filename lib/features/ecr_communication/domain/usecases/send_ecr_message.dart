import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ecr_message.dart';
import '../repositories/ecr_repository.dart';

class SendEcrMessage implements UseCase<bool, SendEcrMessageParams> {
  final EcrRepository repository;

  SendEcrMessage(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendEcrMessageParams params) async {
    return await repository.sendEcrMessage(params.message);
  }
}

class SendEcrMessageParams extends Equatable {
  final EcrMessage message;

  const SendEcrMessageParams({required this.message});

  @override
  List<Object> get props => [message];
}
