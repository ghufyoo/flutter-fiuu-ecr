import 'package:equatable/equatable.dart';

class CommunicationLog extends Equatable {
  final String message;
  final DateTime timestamp;
  final LogType type;

  const CommunicationLog({
    required this.message,
    required this.timestamp,
    required this.type,
  });

  @override
  List<Object> get props => [message, timestamp, type];
}

enum LogType { sent, received, decoded, info, error }
