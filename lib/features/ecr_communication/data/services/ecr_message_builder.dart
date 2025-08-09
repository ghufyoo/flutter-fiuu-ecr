import 'dart:convert';
import 'dart:typed_data';

class EcrMessageBuilder {
  static const int stx = 0x02;
  static const int etx = 0x03;
  static const int separator = 0x1C;

  /// Constructs a Purchase request message.
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

    final List<EcrField> fields = [
      EcrField('00', '00000000000000000000'),
      EcrField('66', transactionId),
      EcrField('40', amount),
      EcrField('M1', merchantIndex),
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
}

/// Represents a single data field in the message body.
class EcrField {
  final String code; // Field Code (ASCII)
  final String data; // Data (ASCII)

  EcrField(this.code, this.data);

  /// Converts the field into its byte representation according to the spec.
  Uint8List toBytes() {
    final builder = BytesBuilder();

    builder.add(utf8.encode(code));

    final dataBytes = utf8.encode(data);
    builder.add(EcrMessageBuilder()._intToBcd(dataBytes.length, 2));

    builder.add(dataBytes);

    builder.addByte(EcrMessageBuilder.separator);

    return builder.toBytes();
  }
}
