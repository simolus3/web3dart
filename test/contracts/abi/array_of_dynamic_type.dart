import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import 'utils.dart';

const encoded =
    // first string starts at offset 64 = 0x40
    '0000000000000000000000000000000000000000000000000000000000000040'
    // second string starts at offset 128 = 0x80
    '0000000000000000000000000000000000000000000000000000000000000080'
    // utf8('Hello').length = 5
    '0000000000000000000000000000000000000000000000000000000000000005'
    // utf-8 encoding of 'hello', right-padded to fill 32 bytes
    '48656c6c6f000000000000000000000000000000000000000000000000000000'
    // utf8('world').length = 5
    '0000000000000000000000000000000000000000000000000000000000000005'
    // utf-8 encoding of 'world', again with padding
    '776f726c64000000000000000000000000000000000000000000000000000000';

void main() {
  const type = FixedLengthArray(type: StringType(), length: 2);

  test('encodes', () {
    expectEncodes(type, ['Hello', 'world'], encoded);
  });

  test('decodes', () {
    final decoded = type.decode(bufferFromHex(encoded), 0);

    expect(decoded.bytesRead, encoded.length ~/ 2);
    expect(decoded.data, ['Hello', 'world']);
  });
}
