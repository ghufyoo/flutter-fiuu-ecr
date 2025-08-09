// Author: ghufyoo
// Error handling failures

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);

  @override
  List<Object> get props => [];
}

class DeviceFailure extends Failure {
  final String message;

  const DeviceFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ConnectionFailure extends Failure {
  final String message;

  const ConnectionFailure(this.message);

  @override
  List<Object> get props => [message];
}

class DataTransmissionFailure extends Failure {
  final String message;

  const DataTransmissionFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ParsingFailure extends Failure {
  final String message;

  const ParsingFailure(this.message);

  @override
  List<Object> get props => [message];
}
