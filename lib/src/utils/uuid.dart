import 'dart:typed_data';

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Formats the [uuid] bytes as an uuid.
String formatUuid(List<int> uuid) => Uuid.unparse(uuid);

/// Generates a v4 uuid.
Uint8List generateUuidV4() {
  final buffer = Uint8List(16);
  _uuid.v4buffer(buffer);
  return buffer;
}

Uint8List parseUuid(String uuid) {
  final buffer = Uint8List(16);
  Uuid.parse(uuid, buffer: buffer);
  return buffer;
}
