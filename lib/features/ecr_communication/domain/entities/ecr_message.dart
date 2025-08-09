import 'package:equatable/equatable.dart';

class EcrMessage extends Equatable {
  final String transactionId;
  final String amount;
  final String merchantIndex;
  final String transactionCode;

  const EcrMessage({
    required this.transactionId,
    required this.amount,
    required this.merchantIndex,
    this.transactionCode = '20', // Default to purchase
  });

  @override
  List<Object> get props => [
    transactionId,
    amount,
    merchantIndex,
    transactionCode,
  ];
}
