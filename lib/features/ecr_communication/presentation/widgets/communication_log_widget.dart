import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/communication_log.dart';

class CommunicationLogWidget extends StatelessWidget {
  final List<CommunicationLog> logs;
  final VoidCallback onClearLogs;

  const CommunicationLogWidget({
    super.key,
    required this.logs,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLogHeader(),
        const SizedBox(height: 8),
        Expanded(child: _buildLogList()),
      ],
    );
  }

  Widget _buildLogHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Communication Log',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'Copy all logs',
              onPressed: _copyAllLogs,
            ),
            ElevatedButton.icon(
              onPressed: onClearLogs,
              icon: const Icon(Icons.delete),
              label: const Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogList() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey.shade50,
      ),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogEntry(log);
        },
      ),
    );
  }

  Widget _buildLogEntry(CommunicationLog log) {
    final color = _getLogTypeColor(log.type);
    final timeString =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:'
        '${log.timestamp.minute.toString().padLeft(2, '0')}:'
        '${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SelectableText(
        '[$timeString] ${log.message}',
        style: TextStyle(fontFamily: 'monospace', color: color, fontSize: 13),
        enableInteractiveSelection: true,
      ),
    );
  }

  Color _getLogTypeColor(LogType type) {
    switch (type) {
      case LogType.sent:
        return Colors.green.shade700;
      case LogType.received:
        return Colors.blue.shade700;
      case LogType.decoded:
        return Colors.purple.shade700;
      case LogType.error:
        return Colors.red.shade700;
      case LogType.info:
        return Colors.black;
    }
  }

  void _copyAllLogs() {
    if (logs.isEmpty) return;

    final allLogsText = logs
        .map((log) {
          final timeString =
              '${log.timestamp.hour.toString().padLeft(2, '0')}:'
              '${log.timestamp.minute.toString().padLeft(2, '0')}:'
              '${log.timestamp.second.toString().padLeft(2, '0')}';
          return '[$timeString] ${log.message}';
        })
        .join('\n');

    Clipboard.setData(ClipboardData(text: allLogsText));
  }
}
