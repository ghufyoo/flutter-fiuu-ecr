import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/ecr_bloc.dart';
import '../bloc/ecr_event.dart';

class HexDataInput extends StatefulWidget {
  const HexDataInput({super.key});

  @override
  State<HexDataInput> createState() => _HexDataInputState();
}

class _HexDataInputState extends State<HexDataInput> {
  final _hexController = TextEditingController(text: "01 03 00 00 00 01 84 0A");

  // Special command from the original code
  static const _specialCommand =
      "02009236303030303030303030313032303030301c3030002030303030303030303030303030303030303030301c363600203030303230323330363230303930393132393731c34300123030303030303030303130301c4d31000230311c03da";

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send Hex Data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      labelText: 'Hex Data to Send',
                      hintText: 'Enter hex data (spaces allowed)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.code),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    final hexData = _hexController.text.trim();
                    if (hexData.isNotEmpty) {
                      context.read<EcrBloc>().add(SendHexDataEvent(hexData));
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<EcrBloc>().add(
                    const SendHexDataEvent(_specialCommand),
                  );
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('Send Special Command'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
