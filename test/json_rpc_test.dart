import 'dart:async';

import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:test_api/test_api.dart';
import 'package:web3dart/json_rpc.dart';

class MockClient extends Mock implements Client {}

void main() {
  final client = MockClient();
  when(client.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
      .thenAnswer((i) {
    return Future.value(Response(
      '{"id": 1, "jsonrpc": "2.0", "result": "0x1"}',
      200,
    ));
  });

  setUp(() => clearInteractions(client));

  test('encodes and sends requests', () async {
    await JsonRPC('url', client).call('eth_gasPrice', ['param', 'another']);

    verify(client.post(
      'url',
      headers: argThat(
        containsPair('Content-Type', 'application/json'),
        named: 'headers',
      ),
      body: anyNamed('body'),
    ));
  });

  test('increments request id', () async {
    final rpc = JsonRPC('url', client);
    await rpc.call('eth_gasPrice', ['param', 'another']);
    await rpc.call('eth_gasPrice', ['param', 'another']);

    verify(client.post(
      'url',
      headers: argThat(
        containsPair('Content-Type', 'application/json'),
        named: 'headers',
      ),
      body: argThat(contains('"id":2'), named: 'body'),
    ));
  });

  test('throws errors', () {
    final rpc = JsonRPC('url', client);
    when(client.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((i) {
          return Future.value(Response(
            '{"id": 1, "jsonrpc": "2.0", '
                '"error": {"code": 1, "message": "Message", "data": "data"}}',
            200,
          ));
    });

    expect(rpc.call('eth_gasPrice'), throwsException);
  });
}
