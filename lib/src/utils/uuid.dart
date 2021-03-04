import 'dart:typed_data';

import 'package:convert/convert.dart';
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
  // Unfortunately, package:uuid is to strict when parsing uuids, the example
  // ids don't work
  final withoutDashes = uuid.replaceAll('-', '');
  final asBytes = hex.decode(withoutDashes);
  return asBytes is Uint8List ? asBytes : Uint8List.fromList(asBytes);
}
