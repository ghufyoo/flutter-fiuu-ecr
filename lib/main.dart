import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:convert/convert.dart';

// Helper extensions for formatting port details (not used by usb_serial, but keep for future)
extension IntToString on int? {
  String toHex() =>
      this == null
          ? 'N/A'
          : '0x${this!.toRadixString(16).toUpperCase().padLeft(4, '0')}';
  String toPadded() => this == null ? 'N/A' : this!.toString().padLeft(3, '0');
}

extension TransportToString on int {
  String toTransport() {
    switch (this) {
      case 1:
        return 'USB';
      case 2:
        return 'Bluetooth';
      case 3:
        return 'Native';
      default:
        return 'Unknown';
    }
  }
}

// Current user and system time constants
const String currentUserLogin = 'ghufyoo';
const String currentSystemTime = '2025-08-01 17:41:37';

// Constants for message construction
const int stx = 0x02;
const int etx = 0x03;
const int separator = 0x1C;

/// Represents a single data field in the message body.
class Field {
  final String code; // Field Code (ASCII)
  final String data; // Data (ASCII)

  Field(this.code, this.data);

  /// Converts the field into its byte representation according to the spec.
  Uint8List toBytes() {
    final builder = BytesBuilder();

    builder.add(utf8.encode(code));

    final dataBytes = utf8.encode(data);
    builder.add(_intToBcd(dataBytes.length, 2));

    builder.add(dataBytes);

    builder.addByte(separator);

    return builder.toBytes();
  }
}

// Response field code meanings based on ECR/FRS/220126/v1.56 specification
Map<String, String> fieldCodeMeanings = {
  '00': 'Pay Account ID',
  '66': 'Transaction ID',
  '02': 'Response Text',
  '40': 'Amount',
  '42': 'Cashback Amount',
  '01': 'Approval Code',
  '65': 'Invoice Number',
  '64': 'Trace Number',
  '29': 'Encrypted Card Number',
  '30': 'Card Number',
  'D4': 'Card Label',
  'D5': 'Cardholder Name',
  '31': 'Expiry Date',
  '32': 'Card Issue Date',
  '33': 'Member Expiry Date',
  '16': 'Terminal ID',
  'D1': 'Merchant No.',
  'D0': 'Merchant Name',
  '50': 'Batch No.',
  '06': 'Retrieval Reference No.',
  'E0': 'AID (EMV)',
  'E1': 'Application Profile (EMV)',
  'E2': 'CID (EMV)',
  'E3': 'Application Cryptogram (EMV)',
  'E4': 'TSI (EMV)',
  'E5': 'TVR (EMV)',
  'E6': 'Card Entry Mode',
  '03': 'Transaction Date',
  '04': 'Transaction Time',
  '38': 'Account Balance',
  'D2': 'Card Issuer Name',
  '17': 'Receipt Footer (merchant copy)',
  '18': 'Receipt Footer (customer copy)',
  '99': 'Custom Data',
  'N8': 'Terminal ID',
  'N4': 'Outlet ID',
  'N5': 'Bill Number',
  'N6': 'Biz Msg ID',
};

// Response transaction result codes from ECR/FRS/220126/v1.56
Map<String, String> transactionResultCodes = {
  '00': 'APPROVED',
  '01': 'PLEASE CALL ISSUER',
  '02': 'PLEASE CALL REFERRAL',
  '03': 'INVLD MERCHANT',
  '04': 'PLS. PICK UP CARD',
  '05': 'DO NOT HONOUR',
  '06': 'ERROR',
  '07': 'Pickup Card, Spl Cond',
  '08': 'VERIFY ID AND SIGN',
  '10': 'Appvd for Partial Amt',
  '11': 'Approved (VIP)',
  '12': 'INVLD TRANSACTION',
  '13': 'INVLD AMT',
  '14': 'INVLD CARD NUM',
  '15': 'No such Issuer',
  '16': 'Approved, Update Tk 3',
  '17': 'Customer Cancellation',
  '18': 'Customer Dispute',
  '19': 'RE-ENTER TRANSACTION',
  '20': 'INVALID RESPONSE',
  '21': 'NO TRANSACTIONS',
  '22': 'Suspected Malfunction',
  '23': 'Unaccepted Trans Fee',
  '24': 'Declined, wrong P55',
  '25': 'Declined, wrong crypto',
  '26': 'Dup Rec,Old Rec Rplcd',
  '27': 'FIELD EDIT ERROR',
  '28': 'FILE LOCKED OUT',
  '29': 'File Update Error',
  '30': 'FORMAT ERROR',
  '31': 'BANK NOT SUPPORTED',
  '32': 'Completed Partially',
  '33': 'EXPIRED CARD',
  '34': 'SUSPECTED FRAUD',
  '35': 'Contact Acquirer',
  '36': 'Restricted Card',
  '37': 'Call Acq. Security',
  '38': 'PIN tries Exceeded',
  '39': 'No Credit Account',
  '40': 'FUNC. NOT SUPPORTED',
  '41': 'LOST CARD',
  '42': 'NO UNIVERSAL ACCOUNT',
  '43': 'Please Call - CC',
  '44': 'No Investment Account',
  '45': 'ISO ERROR #45',
  '46': 'PLS INSERT CARD',
  '47': 'ISO ERROR #47',
  '48': 'ISO ERROR #48',
  '49': 'ISO ERROR #49',
  '50': 'ONLINE PIN REQUESTED',
  '51': 'INSUFFICIENT FUND',
  '52': 'NO CHEQUE ACC',
  '53': 'NO SAVINGS ACCOUNT',
  '54': 'EXPIRED CARD',
  '55': 'Incorrect PIN',
  '56': 'No Card Record',
  '57': 'Txn not Permtd-card',
  '58': 'TRANS NOT PERMITTED',
  '59': 'Suspected Fraud',
  '60': 'CONTACT ACQUIRER',
  '61': 'EXCEED LIMIT',
  '62': 'Restricted Card',
  '63': 'SECURITY VIOLATION',
  '64': 'ORG AMOUNT INCORRECT',
  '65': 'Freq. Limit Exceed',
  '66': 'CALL ACQ\'S SECURITY',
  '67': 'HARD CAPTURE',
  '68': 'Resp Recvd too Late',
  '69': 'ISO ERROR #69',
  '70': 'ISO ERROR #70',
  '71': 'ISO ERROR #71',
  '72': 'ISO ERROR #72',
  '73': 'FUNCTION NOT PERMITTED',
  '74': 'No Comm With Host',
  '75': 'PIN TRIES EXCEED',
  'UA': 'USER ABORT',
  'TO': 'TRANSACTION TIMEOUT',
  'XX': 'CONNECTION ERROR',
};

// Card entry mode descriptions
Map<String, String> cardEntryModes = {
  '10': 'Chip Card Transaction',
  '20': 'Contactless Transaction',
  '30': 'Swipe Transaction',
  '40': 'Fallback Transaction',
  '50': 'Manual Transaction',
  '60': 'QR Transaction',
};

/// Class to parse and display terminal response
class TerminalResponseParser {
  static String parseAndFormatResponse(String rawHex) {
    final decodedText = decodeHexToText(rawHex);
    final fields = extractFields(decodedText);

    final buffer = StringBuffer();
    buffer.writeln('=== DECODED RESPONSE ===');
    buffer.writeln('User: $currentUserLogin | System: $currentSystemTime UTC');

    for (final code in ['D2', '02', '01']) {
      if (fields.containsKey(code)) {
        final cleaned = cleanValue(fields[code]!);
        buffer.writeln('code: $code');
        buffer.writeln('value: $cleaned\n');
      }
    }

    buffer.writeln('--- All Fields ---');
    fields.forEach((code, value) {
      buffer.writeln('$code: ${cleanValue(value)}');
    });

    buffer.writeln('========================');
    return buffer.toString();
  }
}

/// Decode hex string to text. Use \x1C as field separator.
String decodeHexToText(String hex) {
  final buffer = StringBuffer();

  for (int i = 0; i < hex.length; i += 2) {
    final byteStr = hex.substring(i, i + 2);
    final byte = int.parse(byteStr, radix: 16);

    if (byte == 0x1C) {
      buffer.write('\n');
    } else if (byte >= 32 && byte <= 126) {
      buffer.write(String.fromCharCode(byte));
    } else {
      buffer.write('\\x$byteStr');
    }
  }

  return buffer.toString();
}

/// Extract <code>\x00<value> pairs from decoded text.
Map<String, String> extractFields(String input) {
  final fieldMap = <String, String>{};
  final regex = RegExp(r'([0-9A-F]{2})\\x00([^\n]+)');
  for (final match in regex.allMatches(input)) {
    final code = match.group(1);
    final value = match.group(2);
    if (code != null && value != null) {
      fieldMap[code] = value;
    }
  }
  return fieldMap;
}

/// Remove \x but keep the following 2 digits (e.g., \x06 → 06, \x10 → 10)
/// Also removes @
String cleanValue(String raw) {
  final cleaned = raw.replaceAllMapped(
    RegExp(r'\\x([0-9A-Fa-f]{2})'),
    (m) => m.group(1)!,
  );
  return cleaned.replaceAll('@', '').trim();
}

/// Constructs and manages the ECR message.
class EcrMessageBuilder {
  /// Constructs a '20' Purchase request message.
  Uint8List constructPurchaseMessage({
    required String transactionId,
    required String amount,
    required String merchantIndex,
  }) {
    final transportHeader = _buildTransportHeader();
    final presentationHeader = _buildPresentationHeader(
      transactionCode: '20', // '20' for Purchase
      responseCode: '00',
    );

    final List<Field> fields = [
      Field('00', '00000000000000000000'),
      Field('66', transactionId),
      Field('40', amount),
      Field('M1', merchantIndex),
    ];

    final fieldDataBuilder = BytesBuilder();
    for (var field in fields) {
      fieldDataBuilder.add(field.toBytes());
    }

    final messageDataBuilder = BytesBuilder();
    messageDataBuilder.add(transportHeader);
    messageDataBuilder.add(presentationHeader);
    messageDataBuilder.add(fieldDataBuilder.toBytes());
    final messageData = messageDataBuilder.toBytes();

    final messageLengthBytes = _intToBcd(messageData.length, 2);

    final fullMessageBuilder = BytesBuilder();
    fullMessageBuilder.add(messageLengthBytes);
    fullMessageBuilder.add(messageData);

    final lrc = _calculateLrc(fullMessageBuilder.toBytes());

    final finalMessageBuilder = BytesBuilder();
    finalMessageBuilder.addByte(stx);
    finalMessageBuilder.add(fullMessageBuilder.toBytes());
    finalMessageBuilder.addByte(etx);
    finalMessageBuilder.addByte(lrc);

    return finalMessageBuilder.toBytes();
  }

  Uint8List _buildTransportHeader() {
    final builder = BytesBuilder();
    builder.add(utf8.encode('60'));
    builder.add(utf8.encode('0000'));
    builder.add(utf8.encode('0000'));
    return builder.toBytes();
  }

  Uint8List _buildPresentationHeader({
    required String transactionCode,
    required String responseCode,
  }) {
    final builder = BytesBuilder();
    builder.add(utf8.encode('1'));
    builder.add(utf8.encode('0'));
    builder.add(utf8.encode(transactionCode));
    builder.add(utf8.encode(responseCode));
    builder.add(utf8.encode('0'));
    builder.addByte(separator);
    return builder.toBytes();
  }
}

/// Calculates the Longitudinal Redundancy Check (LRC).
int _calculateLrc(Uint8List messageData) {
  int lrc = 0x00;
  for (final byte in messageData) {
    lrc ^= byte;
  }
  lrc ^= etx;
  return lrc;
}

/// Converts an integer to a BCD byte array of a specified length.
Uint8List _intToBcd(int value, int byteCount) {
  final list = Uint8List(byteCount);
  for (int i = byteCount - 1; i >= 0; i--) {
    int bcd = (value % 10);
    value ~/= 10;
    bcd |= (value % 10) << 4;
    value ~/= 10;
    list[i] = bcd;
  }
  return list;
}

// Provider for available USB devices using usb_serial
final availableUsbDevicesProvider = FutureProvider<List<UsbDevice>>((
  ref,
) async {
  try {
    return await UsbSerial.listDevices();
  } catch (e) {
    print('Error getting available USB devices: $e');
    return <UsbDevice>[];
  }
});

// Provider for selected log entry
final selectedLogProvider = StateProvider<int?>((ref) => null);

// Provider for log text selection mode
final logSelectionModeProvider = StateProvider<bool>((ref) => false);

// Provider to manage the state of our app
final serialProvider = StateNotifierProvider<SerialNotifier, SerialState>((
  ref,
) {
  return SerialNotifier();
});

class SerialState {
  final bool isConnected;
  final List<String> receivedData;
  final UsbDevice? selectedDevice;

  SerialState({
    this.isConnected = false,
    this.receivedData = const [],
    this.selectedDevice,
  });

  SerialState copyWith({
    bool? isConnected,
    List<String>? receivedData,
    UsbDevice? selectedDevice,
  }) {
    return SerialState(
      isConnected: isConnected ?? this.isConnected,
      receivedData: receivedData ?? this.receivedData,
      selectedDevice: selectedDevice ?? this.selectedDevice,
    );
  }
}

class SerialNotifier extends StateNotifier<SerialState> {
  SerialNotifier() : super(SerialState());

  UsbPort? _port;
  StreamSubscription<Uint8List>? _subscription;

  void selectDevice(UsbDevice device) {
    state = state.copyWith(selectedDevice: device);
  }

  Future<void> connect() async {
    if (state.selectedDevice == null) {
      _log("Error: No device selected.");
      return;
    }
    if (state.isConnected) {
      _log("Already connected.");
      return;
    }

    _log(
      "Connecting to ${state.selectedDevice!.productName ?? state.selectedDevice!.deviceId}...",
    );

    try {
      _port = await state.selectedDevice!.create();
      bool openResult = await _port!.open();
      if (!openResult) {
        _log("Error: Could not open device.");
        _port = null;
        return;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        115200,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _subscription = _port!.inputStream?.listen(
        (data) {
          final hexString = hex.encode(data);
          _log('RX: $hexString');
          final decodedMessage = TerminalResponseParser.parseAndFormatResponse(
            hexString,
          );
          _logMultiline(decodedMessage);
        },
        onError: (e) {
          _log("Error listening to device: $e");
        },
      );

      state = state.copyWith(isConnected: true);
      _log(
        "Connected to ${state.selectedDevice!.productName ?? state.selectedDevice!.deviceId}",
      );
    } catch (e) {
      _log("Error connecting: $e");
    }
  }

  Future<void> disconnect() async {
    if (!state.isConnected) {
      _log("Not connected.");
      return;
    }
    _log("Disconnecting...");
    await _subscription?.cancel();
    await _port?.close();
    _port = null;
    state = state.copyWith(isConnected: false, selectedDevice: null);
    _log("Disconnected.");
  }

  void sendHex(String hexString) async {
    if (!state.isConnected || _port == null) {
      _log("Error: Not connected. Cannot send data.");
      return;
    }
    try {
      final data = hex.decode(hexString.replaceAll(RegExp(r'\s+'), ''));
      await _port!.write(Uint8List.fromList(data));
      _log('TX: ${hex.encode(data)}');
    } catch (e) {
      _log('Error sending data: $e');
    }
  }

  void sendPaymentRequest({
    required String transactionId,
    required String amount,
    String merchantIndex = '01',
  }) {
    if (!state.isConnected || _port == null) {
      _log("Error: Not connected. Cannot send payment request.");
      return;
    }

    try {
      final formattedAmount = amount.padLeft(12, '0');
      final builder = EcrMessageBuilder();
      final purchaseMessage = builder.constructPurchaseMessage(
        transactionId: transactionId,
        amount: formattedAmount,
        merchantIndex: merchantIndex,
      );

      final hexString = hex.encode(purchaseMessage);
      _log('Sending payment request:');
      _log('Transaction ID: $transactionId');
      _log('Amount: $amount');
      _log('Merchant Index: $merchantIndex');

      sendHex(hexString);
    } catch (e) {
      _log('Error sending payment request: $e');
    }
  }

  void clearLog() {
    state = state.copyWith(receivedData: []);
    _log("Log cleared");
  }

  void _log(String message) {
    final now = DateTime.now();
    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    state = state.copyWith(
      receivedData: ["[$formattedTime] $message", ...state.receivedData],
    );
  }

  void _logMultiline(String message) {
    final now = DateTime.now();
    final formattedTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    final lines = message.split('\n');
    final newEntries = <String>[];
    for (int i = 0; i < lines.length; i++) {
      newEntries.add("[$formattedTime] ${lines[i]}");
    }
    state = state.copyWith(
      receivedData: [...newEntries.reversed, ...state.receivedData],
    );
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Helper function to generate a transaction ID
String generateTransactionId() {
  final now = DateTime.now();
  final date =
      "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
  final time =
      "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
  final random = Random().nextInt(1000).toString().padLeft(3, '0');
  return "0002$date$time$random";
}

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter USB Serial Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serialState = ref.watch(serialProvider);
    final serialNotifier = ref.read(serialProvider.notifier);
    final hexController = TextEditingController(
      text: "01 03 00 00 00 01 84 0A",
    );
    const specialCommand =
        "02009236303030303030303030313032303030301c3030002030303030303030303030303030303030303030301c363600203030303230323330363230303930393132393731c34300123030303030303030303130301c4d31000230311c03da";

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter USB Serial Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!serialState.isConnected) const DeviceSelection(),
            if (serialState.isConnected) ...[
              Text(
                "Connected to ${serialState.selectedDevice?.productName ?? serialState.selectedDevice?.deviceId}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: serialNotifier.disconnect,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Disconnect"),
              ),
              const SizedBox(height: 16),
              _buildSendRow(serialState, hexController, serialNotifier),
              const SizedBox(height: 8),
              _buildSpecialCommandRow(
                serialState,
                serialNotifier,
                specialCommand,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (serialState.isConnected) const PaymentRequestForm(),
              const SizedBox(height: 16),
            ],
            _buildLogHeader(serialNotifier, ref),
            Expanded(child: LogView()),
          ],
        ),
      ),
    );
  }

  Widget _buildSendRow(
    SerialState serialState,
    TextEditingController hexController,
    SerialNotifier serialNotifier,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: hexController,
            decoration: const InputDecoration(
              labelText: 'Hex Data to Send',
              border: OutlineInputBorder(),
            ),
            enabled: serialState.isConnected,
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed:
              serialState.isConnected
                  ? () => serialNotifier.sendHex(hexController.text)
                  : null,
          child: const Text('Send'),
        ),
      ],
    );
  }

  Widget _buildSpecialCommandRow(
    SerialState serialState,
    SerialNotifier serialNotifier,
    String command,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed:
                serialState.isConnected
                    ? () => serialNotifier.sendHex(command)
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            child: const Text('Send Special Command'),
          ),
        ),
      ],
    );
  }

  Widget _buildLogHeader(SerialNotifier serialNotifier, WidgetRef ref) {
    final isSelectionMode = ref.watch(logSelectionModeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Communication Log',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Wrap(
          spacing: 8,
          children: [
            if (isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copy selected log entry',
                onPressed: () {
                  final selectedIndex = ref.read(selectedLogProvider);
                  if (selectedIndex != null) {
                    final logs = ref.read(serialProvider).receivedData;
                    if (selectedIndex < logs.length) {
                      Clipboard.setData(
                        ClipboardData(text: logs[selectedIndex]),
                      );
                      ScaffoldMessenger.of(ref.context).showSnackBar(
                        const SnackBar(
                          content: Text('Log entry copied to clipboard'),
                        ),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.copy_all),
                tooltip: 'Copy all log entries',
                onPressed: () {
                  final logs = ref.read(serialProvider).receivedData;
                  if (logs.isNotEmpty) {
                    final allLogs = logs.join('\n');
                    Clipboard.setData(ClipboardData(text: allLogs));
                    ScaffoldMessenger.of(ref.context).showSnackBar(
                      const SnackBar(
                        content: Text('All logs copied to clipboard'),
                      ),
                    );
                  }
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(logSelectionModeProvider.notifier).state = false;
                  ref.read(selectedLogProvider.notifier).state = null;
                },
                icon: const Icon(Icons.close),
                label: const Text('Exit Selection'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(logSelectionModeProvider.notifier).state = true;
                },
                icon: const Icon(Icons.highlight_alt),
                label: const Text('Select'),
              ),
            ],
            ElevatedButton.icon(
              onPressed: serialNotifier.clearLog,
              icon: const Icon(Icons.delete),
              label: const Text('Clear Log'),
            ),
          ],
        ),
      ],
    );
  }
}

class LogView extends ConsumerWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serialState = ref.watch(serialProvider);
    final selectedLogIndex = ref.watch(selectedLogProvider);
    final isSelectionMode = ref.watch(logSelectionModeProvider);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: serialState.receivedData.length,
        itemBuilder: (context, index) {
          final log = serialState.receivedData[index];
          final color =
              log.contains('RX:')
                  ? Colors.blue.shade700
                  : (log.contains('TX:')
                      ? Colors.green.shade700
                      : (log.contains('DECODED:') || log.contains('===')
                          ? Colors.purple.shade700
                          : Colors.black));

          return SelectableLogEntry(
            log: log,
            index: index,
            color: color,
            isSelected: selectedLogIndex == index,
            isSelectionMode: isSelectionMode,
          );
        },
      ),
    );
  }
}

class SelectableLogEntry extends ConsumerWidget {
  final String log;
  final int index;
  final Color color;
  final bool isSelected;
  final bool isSelectionMode;

  const SelectableLogEntry({
    required this.log,
    required this.index,
    required this.color,
    required this.isSelected,
    required this.isSelectionMode,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap:
          isSelectionMode
              ? () {
                ref.read(selectedLogProvider.notifier).state = index;
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          children: [
            if (isSelectionMode) ...[
              SizedBox(
                width: 24,
                child:
                    isSelected
                        ? const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.blue,
                        )
                        : const Icon(
                          Icons.circle_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: SelectableText(
                log,
                style: TextStyle(fontFamily: 'monospace', color: color),
                enableInteractiveSelection: true,
                toolbarOptions: const ToolbarOptions(
                  copy: true,
                  selectAll: true,
                  cut: false,
                  paste: false,
                ),
                contextMenuBuilder: (context, editableTextState) {
                  return AdaptiveTextSelectionToolbar(
                    anchors: editableTextState.contextMenuAnchors,
                    children: [
                      InkWell(
                        onTap: () {
                          editableTextState.copySelection(
                            SelectionChangedCause.toolbar,
                          );
                          editableTextState.hideToolbar();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: const Text('Copy'),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          editableTextState.selectAll(
                            SelectionChangedCause.toolbar,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: const Text('Select All'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentRequestForm extends ConsumerStatefulWidget {
  const PaymentRequestForm({super.key});

  @override
  _PaymentRequestFormState createState() => _PaymentRequestFormState();
}

class _PaymentRequestFormState extends ConsumerState<PaymentRequestForm> {
  final amountController = TextEditingController();
  final transactionIdController = TextEditingController();
  final merchantIndexController = TextEditingController(text: '01');

  @override
  void initState() {
    super.initState();
    transactionIdController.text = generateTransactionId();
  }

  @override
  void dispose() {
    amountController.dispose();
    transactionIdController.dispose();
    merchantIndexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serialNotifier = ref.read(serialProvider.notifier);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (in cents)',
                hintText: 'e.g., 1000 for \$10.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: transactionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      transactionIdController.text = generateTransactionId();
                    });
                  },
                  child: const Text('Generate'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: merchantIndexController,
              decoration: const InputDecoration(
                labelText: 'Merchant Index',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an amount')),
                    );
                    return;
                  }
                  if (transactionIdController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a transaction ID'),
                      ),
                    );
                    return;
                  }
                  serialNotifier.sendPaymentRequest(
                    transactionId: transactionIdController.text,
                    amount: amountController.text,
                    merchantIndex:
                        merchantIndexController.text.isEmpty
                            ? '01'
                            : merchantIndexController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Send Payment Request',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Device selection widget using usb_serial
class DeviceSelection extends ConsumerWidget {
  const DeviceSelection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(availableUsbDevicesProvider);
    final serialState = ref.watch(serialProvider);
    final serialNotifier = ref.read(serialProvider.notifier);

    return deviceAsync.when(
      data:
          (devices) => Column(
            children: [
              if (devices.isEmpty)
                const Center(child: Text("No USB devices found."))
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView(
                    children:
                        devices
                            .map((device) => DeviceInfoCard(device: device))
                            .toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => ref.refresh(availableUsbDevicesProvider),
                    child: const Text('Refresh Devices'),
                  ),
                  ElevatedButton(
                    onPressed:
                        serialState.selectedDevice != null
                            ? serialNotifier.connect
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: const Text('Connect'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
            ],
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}

class DeviceInfoCard extends ConsumerWidget {
  final UsbDevice device;
  const DeviceInfoCard({required this.device, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serialState = ref.watch(serialProvider);
    final serialNotifier = ref.read(serialProvider.notifier);
    final bool isSelected = serialState.selectedDevice == device;

    return Card(
      elevation: 2,
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        title: Text(device.productName ?? device.deviceId.toString()),
        subtitle: Text('Vendor: ${device.vid}, Product: ${device.pid}'),
        leading: Radio<UsbDevice>(
          value: device,
          groupValue: serialState.selectedDevice,
          onChanged: (value) {
            if (value != null) {
              serialNotifier.selectDevice(value);
            }
          },
        ),
      ),
    );
  }
}
