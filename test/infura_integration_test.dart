@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/contracts/erc20.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  final infuraProjectId = Platform.environment['INFURA_ID'];

  group(
    'integration',
    () {
      late final Web3Client client;

      setUpAll(() {
        client = Web3Client(
            'https://mainnet.infura.io/v3/$infuraProjectId', Client());
      });

      // ignore: unnecessary_lambdas, https://github.com/dart-lang/linter/issues/2670
      tearDownAll(() => client.dispose());

      test('erc20 get balance', () async {
        final shibaInu = Erc20(
          address: EthereumAddress.fromHex(
              '0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce'),
          client: client,
        );

        final balance = await shibaInu.balanceOf(EthereumAddress.fromHex(
            '0xdead000000000000000042069420694206942069'));

        expect(balance >= BigInt.parse('410243042034234643784017156276017'),
            isTrue);
      });

      test('Web3Client.getBlockInformation', () async {
        final blockInfo = await client.getBlockInformation(
          blockNumber: const BlockNum.exact(14074702).toBlockParam(),
        );

        expect(
          blockInfo.timestamp.millisecondsSinceEpoch == 1643113026000,
          isTrue,
        );
        expect(
          blockInfo.timestamp.isUtc == true,
          isTrue,
        );
      });
    },
    skip: infuraProjectId == null || infuraProjectId.length < 32
        ? 'Tests require the INFURA_ID environment variable'
        : null,
  );
}
