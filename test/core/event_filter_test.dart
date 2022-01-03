import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import '../mock_client.dart';

void main() {
  const alice =
      '0x000000000000000000000000Dd611f2b2CaF539aC9e12CF84C09CB9bf81CA37F';
  const bob =
      '0x0000000000000000000000006c87E1a114C3379BEc929f6356c5263d62542C13';
  const contract = '0x16c5785ac562ff41e2dcfdf829c5a142f1fccd7d';

  final testCases = [
    {
      'name': 'one topic',
      'input': [
        [alice]
      ],
      'expected': [
        [alice]
      ]
    },
    {
      'name': 'two topics one item',
      'input': [
        [alice, bob]
      ],
      'expected': [
        [alice, bob]
      ]
    },
    {
      'name': 'two topics two items',
      'input': [
        [alice],
        [bob]
      ],
      'expected': [
        [alice],
        [bob]
      ]
    },
    {
      'name': 'two topics first null',
      'input': [
        [],
        [bob]
      ],
      'expected': [
        null,
        [bob]
      ]
    },
    {
      'name': 'three topics first null',
      'input': [
        [],
        [alice],
        [bob]
      ],
      'expected': [
        null,
        [alice],
        [bob]
      ]
    },
    {
      'name': 'three topics second null',
      'input': [
        [alice],
        [],
        [bob]
      ],
      'expected': [
        [alice],
        null,
        [bob]
      ]
    }
  ];

  Future _runFilterTest(input, expected) async {
    final client = MockClient(expectAsync2((method, params) {
      expect(method, 'eth_getLogs');

      // verify that the topics are sent to eth_getLogs in the correct format
      final actual = ((params as List)[0])['topics'];
      expect(actual, expected);

      // return a valid response from eth_getLogs
      return [
        {'address': contract}
      ];
    }));

    final web3 = Web3Client('', client);
    addTearDown(web3.dispose);

    // Dart typing will not allow an empty list to be added so when an empty
    // list is encountered, a list containing a single string is added and then
    // the single string in that list is removed.
    // The type is required to ensure `topics` is forced to List<List<String>>

    // ignore: omit_local_variable_types
    final List<List<String>> topics = [];
    input.forEach((element) {
      if (element.length == 0) {
        topics.add(['dummy string element']);
        topics.last.remove('dummy string element');
      } else {
        topics.add(element as List<String>);
      }
    });

    final filter = FilterOptions(
        fromBlock: const BlockNum.genesis(),
        toBlock: const BlockNum.current(),
        address: EthereumAddress.fromHex(contract),
        topics: topics);

    await web3.getLogs(filter);
  }

  // test each test case in the list of test cases
  for (final testCase in testCases) {
    test('filters test with ${testCase['name']}', () async {
      await _runFilterTest(testCase['input'], testCase['expected']);
    });
  }
}
