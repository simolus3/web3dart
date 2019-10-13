import 'package:test/test.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  final event = ContractEvent(false, 'Transfer', const [
    EventComponent(FunctionParameter('from', AddressType()), true),
    EventComponent(FunctionParameter('to', AddressType()), true),
    EventComponent(FunctionParameter('amount', UintType()), false),
  ]);

  test('creates signature', () {
    expect(bytesToHex(event.signature),
        'ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef');
  });

  test('decodes return data', () {
    final topics = [
      '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
      '0x000000000000000000000000Dd611f2b2CaF539aC9e12CF84C09CB9bf81CA37F',
      '0x0000000000000000000000006c87E1a114C3379BEc929f6356c5263d62542C13',
    ];
    final data =
        '0x0000000000000000000000000000000000000000000000000000000000001234';

    final decoded = event.decodeResults(topics, data);

    expect(decoded, [
      EthereumAddress.fromHex('0xDd611f2b2CaF539aC9e12CF84C09CB9bf81CA37F'),
      EthereumAddress.fromHex('0x6c87E1a114C3379BEc929f6356c5263d62542C13'),
      BigInt.from(0x1234),
    ]);
  });
}
