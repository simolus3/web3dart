import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/keccak.dart';
import '../utils/typed_data.dart';

final KeccakDigest keccakDigest = KeccakDigest(256);

Uint8List keccak256(Uint8List input) {
  keccakDigest.reset();
  return keccakDigest.process(input);
}

Uint8List keccakUtf8(String input) {
  return keccak256(uint8ListFromList(utf8.encode(input)));
}

Uint8List keccakAscii(String input) {
  return keccak256(ascii.encode(input));
}
