// Author: ghufyoo
// ECR BLoC for state management

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/communication_log.dart';
import '../../domain/usecases/connect_to_device.dart';
import '../../domain/usecases/disconnect_from_device.dart';
import '../../domain/usecases/get_available_devices.dart';
import '../../domain/usecases/send_ecr_message.dart';
import '../../domain/repositories/ecr_repository.dart';
import '../services/terminal_response_parser.dart';
import 'ecr_event.dart';
import 'ecr_state.dart';

class EcrBloc extends Bloc<EcrEvent, EcrState> {
  final GetAvailableDevices getAvailableDevices;
  final ConnectToDevice connectToDevice;
  final DisconnectFromDevice disconnectFromDevice;
  final SendEcrMessage sendEcrMessage;
  final EcrRepository repository;
  final TerminalResponseParser responseParser;

  StreamSubscription<String>? _dataSubscription;
  final List<CommunicationLog> _logs = [];

  EcrBloc({
    required this.getAvailableDevices,
    required this.connectToDevice,
    required this.disconnectFromDevice,
    required this.sendEcrMessage,
    required this.repository,
    required this.responseParser,
  }) : super(EcrInitial()) {
    on<LoadAvailableDevices>(_onLoadAvailableDevices);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectFromDeviceEvent>(_onDisconnectFromDevice);
    on<SendHexDataEvent>(_onSendHexData);
    on<SendEcrMessageEvent>(_onSendEcrMessage);
    on<DataReceivedEvent>(_onDataReceived);
    on<ClearLogsEvent>(_onClearLogs);
  }

  Future<void> _onLoadAvailableDevices(
    LoadAvailableDevices event,
    Emitter<EcrState> emit,
  ) async {
    emit(EcrLoading());

    final result = await getAvailableDevices(const NoParams());

    result.fold(
      (failure) => emit(EcrError(failure.toString())),
      (devices) => emit(EcrDevicesLoaded(devices)),
    );
  }

  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event,
    Emitter<EcrState> emit,
  ) async {
    emit(EcrLoading());

    final result = await connectToDevice(
      ConnectToDeviceParams(device: event.device),
    );

    result.fold((failure) => emit(EcrError(failure.toString())), (success) {
      if (success) {
        _startListeningToDataStream();
        _addLog(
          'Connected to ${event.device.productName ?? event.device.deviceId}',
          LogType.info,
        );

        // Get available devices for the connected state
        getAvailableDevices(const NoParams()).then((devicesResult) {
          devicesResult.fold(
            (failure) => emit(EcrError(failure.toString())),
            (devices) => emit(
              EcrDeviceConnected(
                device: event.device,
                availableDevices: devices,
                logs: List.from(_logs),
              ),
            ),
          );
        });
      } else {
        emit(const EcrError('Failed to connect to device'));
      }
    });
  }

  Future<void> _onDisconnectFromDevice(
    DisconnectFromDeviceEvent event,
    Emitter<EcrState> emit,
  ) async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;

    final result = await disconnectFromDevice(const NoParams());

    result.fold((failure) => emit(EcrError(failure.toString())), (success) {
      _addLog('Disconnected from device', LogType.info);

      // Load available devices again
      add(LoadAvailableDevices());
    });
  }

  Future<void> _onSendHexData(
    SendHexDataEvent event,
    Emitter<EcrState> emit,
  ) async {
    final result = await repository.sendHexData(event.hexData);

    result.fold(
      (failure) {
        _addLog('Error sending data: ${failure.toString()}', LogType.error);
        _emitCurrentState(emit);
      },
      (success) {
        final cleanedHex = event.hexData.replaceAll(RegExp(r'\s+'), '');
        _addLog('TX: $cleanedHex', LogType.sent);
        _emitCurrentState(emit);
      },
    );
  }

  Future<void> _onSendEcrMessage(
    SendEcrMessageEvent event,
    Emitter<EcrState> emit,
  ) async {
    final result = await sendEcrMessage(
      SendEcrMessageParams(message: event.message),
    );

    result.fold(
      (failure) {
        _addLog(
          'Error sending ECR message: ${failure.toString()}',
          LogType.error,
        );
        _emitCurrentState(emit);
      },
      (success) {
        _addLog('Sending payment request:', LogType.info);
        _addLog('Transaction ID: ${event.message.transactionId}', LogType.info);
        _addLog('Amount: ${event.message.amount}', LogType.info);
        _addLog('Merchant Index: ${event.message.merchantIndex}', LogType.info);
        _emitCurrentState(emit);
      },
    );
  }

  void _onDataReceived(DataReceivedEvent event, Emitter<EcrState> emit) {
    _addLog('RX: ${event.data}', LogType.received);

    // Parse the response
    final decodedMessage = responseParser.parseAndFormatResponse(event.data);
    final lines = decodedMessage.split('\n');
    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        _addLog(line, LogType.decoded);
      }
    }

    _emitCurrentState(emit);
  }

  void _onClearLogs(ClearLogsEvent event, Emitter<EcrState> emit) {
    _logs.clear();
    _addLog('Log cleared', LogType.info);
    _emitCurrentState(emit);
  }

  void _startListeningToDataStream() {
    _dataSubscription = repository.dataStream.listen(
      (data) => add(DataReceivedEvent(data)),
      onError: (error) => add(DataReceivedEvent('Error: $error')),
    );
  }

  void _addLog(String message, LogType type) {
    final log = CommunicationLog(
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    _logs.insert(0, log); // Add to beginning for reverse chronological order
  }

  void _emitCurrentState(Emitter<EcrState> emit) {
    final currentState = state;
    if (currentState is EcrDeviceConnected) {
      emit(currentState.copyWith(logs: List.from(_logs)));
    }
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}
