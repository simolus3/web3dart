import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:test_api/test_api.dart';

void main() {
  test('signs transactions', () async {
    final credentials = EthPrivateKey.fromHex(
        'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e');
    final transaction = Transaction(
      from: await credentials.extractAddress(),
      to: EthereumAddress.fromHex('0xC914Bb2ba888e3367bcecEb5C2d99DF7C7423706'),
      nonce: 0,
      gasPrice: EtherAmount.inWei(BigInt.one),
      maxGas: 10,
      value: EtherAmount.inWei(BigInt.from(10)),
    );

    final client = Web3Client(null, null);
    final signature = await client.signTransaction(credentials, transaction);

    expect(bytesToHex(signature),
        'f85d80010a94c914bb2ba888e3367bceceb5c2d99df7c74237060a8025a0a78c2f8b0f95c33636b2b1b91d3d23844fba2ec1b2168120ad64b84565b94bcda0365ecaff22197e3f21816cf9d428d695087ad3a8b7f93456cd48311d71402578');
  });

  // example from https://github.com/ethereum/EIPs/issues/155
  test('signs eip 155 transaction', () async {
    final credentials = EthPrivateKey.fromHex(
        '0x4646464646464646464646464646464646464646464646464646464646464646');

    final transaction = Transaction(
      nonce: 9,
      gasPrice: EtherAmount.inWei(BigInt.from(20000000000)),
      maxGas: 21000,
      to: EthereumAddress.fromHex('0x3535353535353535353535353535353535353535'),
      value: EtherAmount.inWei(BigInt.from(1000000000000000000)),
    );

    final client = Web3Client(null, null);
    final signature = await client.signTransaction(credentials, transaction);

    expect(
        bytesToHex(signature),
        'f86c098504a817c800825208943535353535353535353535353535353535353535880'
        'de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d'
        '3c71ff63e1590620aa636276a067cbe9d8997f761aecb703304b3800ccf55'
        '5c9f3dc64214b297fb1966a3b6d83');
  });
}
