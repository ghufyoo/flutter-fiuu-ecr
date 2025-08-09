import '../../features/ecr_communication/data/datasources/serial_data_source.dart';
import '../../features/ecr_communication/data/repositories/ecr_repository_impl.dart';
import '../../features/ecr_communication/data/services/ecr_message_builder.dart';
import '../../features/ecr_communication/domain/repositories/ecr_repository.dart';
import '../../features/ecr_communication/domain/usecases/connect_to_device.dart';
import '../../features/ecr_communication/domain/usecases/disconnect_from_device.dart';
import '../../features/ecr_communication/domain/usecases/get_available_devices.dart';
import '../../features/ecr_communication/domain/usecases/send_ecr_message.dart';
import '../../features/ecr_communication/presentation/bloc/ecr_bloc.dart';
import '../../features/ecr_communication/presentation/services/terminal_response_parser.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  void init() {
    // Data sources
    _services[SerialDataSource] = SerialDataSourceImpl();

    // Services
    _services[EcrMessageBuilder] = EcrMessageBuilder();
    _services[TerminalResponseParser] = TerminalResponseParser();

    // Repository
    _services[EcrRepository] = EcrRepositoryImpl(
      serialDataSource: _services[SerialDataSource],
      messageBuilder: _services[EcrMessageBuilder],
    );

    // Use cases
    _services[GetAvailableDevices] = GetAvailableDevices(
      _services[EcrRepository],
    );
    _services[ConnectToDevice] = ConnectToDevice(_services[EcrRepository]);
    _services[DisconnectFromDevice] = DisconnectFromDevice(
      _services[EcrRepository],
    );
    _services[SendEcrMessage] = SendEcrMessage(_services[EcrRepository]);
  }

  T get<T>() {
    if (!_services.containsKey(T)) {
      throw Exception('Service of type $T is not registered');
    }
    return _services[T];
  }

  EcrBloc createEcrBloc() {
    return EcrBloc(
      getAvailableDevices: get<GetAvailableDevices>(),
      connectToDevice: get<ConnectToDevice>(),
      disconnectFromDevice: get<DisconnectFromDevice>(),
      sendEcrMessage: get<SendEcrMessage>(),
      repository: get<EcrRepository>(),
      responseParser: get<TerminalResponseParser>(),
    );
  }
}
