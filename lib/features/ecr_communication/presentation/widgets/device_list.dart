import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/usb_device_entity.dart';
import '../bloc/ecr_bloc.dart';
import '../bloc/ecr_event.dart';

class DeviceList extends StatelessWidget {
  final List<UsbDeviceEntity> devices;
  final UsbDeviceEntity? selectedDevice;

  const DeviceList({super.key, required this.devices, this.selectedDevice});

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const Center(
        child: Text('No USB devices found', style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        const Text(
          'Available Devices',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final isSelected = selectedDevice?.deviceId == device.deviceId;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: isSelected ? Colors.blue.shade50 : null,
                child: ListTile(
                  title: Text(
                    device.productName ?? 'Device ${device.deviceId}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'VID: ${device.vid.toRadixString(16).toUpperCase().padLeft(4, '0')}, '
                    'PID: ${device.pid.toRadixString(16).toUpperCase().padLeft(4, '0')}',
                  ),
                  leading: Radio<UsbDeviceEntity>(
                    value: device,
                    groupValue: selectedDevice,
                    onChanged: (value) {
                      if (value != null) {
                        // Store selected device (you might want to add this to the BLoC)
                      }
                    },
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      context.read<EcrBloc>().add(ConnectToDeviceEvent(device));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Connect'),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.read<EcrBloc>().add(LoadAvailableDevices());
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Devices'),
        ),
      ],
    );
  }
}
