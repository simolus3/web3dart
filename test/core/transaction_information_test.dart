import 'dart:convert';

import 'package:test/test.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  test('parses full object', () async {
    final parsed = TransactionReceipt.fromMap(json.decode('''
{
  "blockHash": "0x5548b5f215b99674c7f23c9a701a005b5c18e4a963b55163eddada54562ac521",
  "blockNumber": "0x18",
  "contractAddress": "0x6671e02bb8bd3a234b13d79d1c285a9df657233d",
  "cumulativeGasUsed": "0x4cc5f",
  "from": "0xf8c59caf9bb8a7a2991160b592ac123108d88f7b",
  "gasUsed": "0x4cc5f",
  "logs": [
    {
      "logIndex": "0x1",
      "blockNumber": "0x1b4",
      "blockHash": "0x8216c5785ac562ff41e2dcfdf5785ac562ff41e2dcfdf829c5a142f1fccd7d",
      "transactionHash": "0xdf829c5a142f1fccd7d8216c5785ac562ff41e2dcfdf5785ac562ff41e2dcf",
      "transactionIndex": "0x0",
      "address": "0x16c5785ac562ff41e2dcfdf829c5a142f1fccd7d",
       "data": "0x0000000000000000000000000000000000000000000000000000000000000000",
       "topics": ["0x59ebeb90bc63057b6515673c3ecf9438e5058bca0f92585014eced636878c9a5"]
    }
  ],
  "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "root": "0x89628cd74b7246a144781e0f537bac145df645945c213f82ab45f4c6729f1e4c",
  "to": "0xf8c59caf9bb8a7a2991160b592ac123108d88f7b",
  "transactionHash": "0xb75a96c4751ff03b1bdcf5300e80a45e788e52650b0a4e2294e7496c215f4c9d",
  "transactionIndex": "0x18",
  "status": "0x1"
}
  ''') as Map<String, dynamic>);
    expect(
        parsed,
        TransactionReceipt(
            transactionHash: hexToBytes(
                '0xb75a96c4751ff03b1bdcf5300e80a45e788e52650b0a4e2294e7496c215f4c9d'),
            transactionIndex: 24,
            blockHash: hexToBytes(
                '0x5548b5f215b99674c7f23c9a701a005b5c18e4a963b55163eddada54562ac521'),
            cumulativeGasUsed: BigInt.from(314463),
            blockNumber: const BlockNum.exact(24),
            contractAddress: EthereumAddress.fromHex(
                '0x6671e02bb8bd3a234b13d79d1c285a9df657233d'),
            status: true,
            from: EthereumAddress.fromHex(
                '0xf8c59caf9bb8a7a2991160b592ac123108d88f7b'),
            to: EthereumAddress.fromHex(
                '0xf8c59caf9bb8a7a2991160b592ac123108d88f7b'),
            gasUsed: BigInt.from(314463),
            logs: [
              FilterEvent(
                  removed: false,
                  logIndex: 1,
                  blockNum: 436,
                  blockHash:
                      '0x8216c5785ac562ff41e2dcfdf5785ac562ff41e2dcfdf829c5a142f1fccd7d',
                  transactionHash: '0xdf829c5a142f1fccd7d8216c5785ac562ff41e2dcfdf5785ac562ff41e2dcf',
                  transactionIndex: 0,
                  address: EthereumAddress.fromHex('0x16c5785ac562ff41e2dcfdf829c5a142f1fccd7d'),
                  data: '0x0000000000000000000000000000000000000000000000000000000000000000',
                  topics: [
                    '0x59ebeb90bc63057b6515673c3ecf9438e5058bca0f92585014eced636878c9a5'
                  ])
            ]));
  });
  test('parses incomplete object', () async {
    final parsed = TransactionReceipt.fromMap(json.decode('''
{
  "blockHash": "0x5548b5f215b99674c7f23c9a701a005b5c18e4a963b55163eddada54562ac521",
  "cumulativeGasUsed": "0x4cc5f",
  "transactionHash": "0xb75a96c4751ff03b1bdcf5300e80a45e788e52650b0a4e2294e7496c215f4c9d",
  "transactionIndex": "0x18"
}
  ''') as Map<String, dynamic>);
    expect(
        parsed,
        TransactionReceipt(
          transactionHash: hexToBytes(
              '0xb75a96c4751ff03b1bdcf5300e80a45e788e52650b0a4e2294e7496c215f4c9d'),
          transactionIndex: 24,
          blockHash: hexToBytes(
              '0x5548b5f215b99674c7f23c9a701a005b5c18e4a963b55163eddada54562ac521'),
          cumulativeGasUsed: BigInt.from(314463),
        ));
  });
}
