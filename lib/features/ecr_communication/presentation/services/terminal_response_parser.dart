class TerminalResponseParser {
  // Current user and system time constants
  static const String currentUserLogin = 'ghufyoo';
  static const String currentSystemTime = '2025-08-01 17:41:37';

  String parseAndFormatResponse(String rawHex) {
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
}
