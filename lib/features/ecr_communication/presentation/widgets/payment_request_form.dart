// Author: ghufyoo
// Payment request form widget

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ecr_message.dart';
import '../bloc/ecr_bloc.dart';
import '../bloc/ecr_event.dart';

class PaymentRequestForm extends StatefulWidget {
  const PaymentRequestForm({super.key});

  @override
  State<PaymentRequestForm> createState() => _PaymentRequestFormState();
}

class _PaymentRequestFormState extends State<PaymentRequestForm> {
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _merchantIndexController = TextEditingController(text: '01');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _transactionIdController.text = _generateTransactionId();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _merchantIndexController.dispose();
    super.dispose();
  }

  String _generateTransactionId() {
    final now = DateTime.now();
    final date =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final time =
        "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    final random = Random().nextInt(1000).toString().padLeft(3, '0');
    return "0002$date$time$random";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Request',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (in cents)',
                  hintText: 'e.g., 1000 for \$10.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _transactionIdController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a transaction ID';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _transactionIdController.text =
                            _generateTransactionId();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merchantIndexController,
                decoration: const InputDecoration(
                  labelText: 'Merchant Index',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a merchant index';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendPaymentRequest,
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Send Payment Request',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendPaymentRequest() {
    if (_formKey.currentState!.validate()) {
      final message = EcrMessage(
        transactionId: _transactionIdController.text,
        amount: _amountController.text,
        merchantIndex: _merchantIndexController.text,
      );

      context.read<EcrBloc>().add(SendEcrMessageEvent(message));
    }
  }
}
