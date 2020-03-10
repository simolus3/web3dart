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
}
