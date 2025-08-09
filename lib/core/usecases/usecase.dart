// Author: ghufyoo
// Base use case interface

import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Use cases are the entry points to the domain layer.
/// They contain the business logic for a specific use case.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
