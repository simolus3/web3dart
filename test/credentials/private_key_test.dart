import 'dart:convert';

import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:test/test.dart';

void main() {
  test('signs messages', () async {
    final key = EthPrivateKey(hexToBytes(
        'a392604efc2fad9c0b3da43b5f698a2e3f270f170d859912be0d54742275c5f6'));
    final signature =
        await key.signPersonalMessage(ascii.encode('A test message'));

    expect(bytesToHex(signature),
        '0464eee9e2fe1a10ffe48c78b80de1ed8dcf996f3f60955cb2e03cb21903d93006624da478b3f862582e85b31c6a21c6cae2eee2bd50f55c93c4faad9d9c8d7f1c');
  });

  test('signs message for chainId', () async {
    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/test/index.js#L532
    final key = EthPrivateKey(hexToBytes(
        '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1'));
    final signature = await key.sign(
        hexToBytes(
            '0x3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1'),
        chainId: 3);

    expect(
      bytesToHex(signature),
      '99e71a99cb2270b8cac5254f9e99b6210c6c10224a1579cf389ef88b20a1abe9'
      '129ff05af364204442bdb53ab6f18a99ab48acc9326fa689f228040429e3ca66'
      '29',
    );
  });
}
