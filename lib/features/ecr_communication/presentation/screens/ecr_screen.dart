// Author: ghufyoo
// Main ECR communication screen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ecr_bloc.dart';
import '../bloc/ecr_event.dart';
import '../bloc/ecr_state.dart';
import '../widgets/communication_log_widget.dart';
import '../widgets/device_list.dart';
import '../widgets/hex_data_input.dart';
import '../widgets/payment_request_form.dart';

class EcrScreen extends StatefulWidget {
  const EcrScreen({super.key});

  @override
  State<EcrScreen> createState() => _EcrScreenState();
}

class _EcrScreenState extends State<EcrScreen> {
  @override
  void initState() {
    super.initState();
    // Load available devices when the screen initializes
    context.read<EcrBloc>().add(LoadAvailableDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter ECR Communication'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<EcrBloc, EcrState>(
        listener: (context, state) {
          if (state is EcrError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return _buildBody(state);
        },
      ),
    );
  }

  Widget _buildBody(EcrState state) {
    if (state is EcrLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is EcrDevicesLoaded) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: DeviceList(devices: state.devices),
      );
    }

    if (state is EcrDeviceConnected) {
      return _buildConnectedView(state);
    }

    if (state is EcrError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<EcrBloc>().add(LoadAvailableDevices());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('Initializing...'));
  }

  Widget _buildConnectedView(EcrDeviceConnected state) {
    return Column(
      children: [
        // Connected device info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connected to: ${state.device.productName ?? state.device.deviceId}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<EcrBloc>().add(DisconnectFromDeviceEvent());
                },
                icon: const Icon(Icons.close),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Main content area
        Expanded(
          child: Row(
            children: [
              // Left side - Controls
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const HexDataInput(),
                      const PaymentRequestForm(),
                    ],
                  ),
                ),
              ),

              // Right side - Communication log
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CommunicationLogWidget(
                    logs: state.logs,
                    onClearLogs: () {
                      context.read<EcrBloc>().add(ClearLogsEvent());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
