import 'package:test/test.dart';
import 'package:web3dart/crypto.dart';

void main() {
  test('strip 0x prefix', () {
    expect(strip0x('0x12F312319235'), '12F312319235');
    expect(strip0x('123123'), '123123');
  });

  test('hexToDartInt', () {
    expect(hexToDartInt('0x123'), 0x123);
    expect(hexToDartInt('0xff'), 0xff);
    expect(hexToDartInt('abcdef'), 0xabcdef);
  });

  test('hexToBytes handles odd length', () {
    expect(
        hexToBytes(
            '0xcf1daa12796907b13c6e104ee7185eb8b1e34db92b55a4655c147ff2fe5563c'),
        hexToBytes(
            '0x0cf1daa12796907b13c6e104ee7185eb8b1e34db92b55a4655c147ff2fe5563c'));
  });
}
