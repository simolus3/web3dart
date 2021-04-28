import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/json_rpc.dart';

final uri = Uri.parse('url');

void main() {
  late MockClient client;

  setUp(() {
    client = MockClient();
  });

  test('encodes and sends requests', () async {
    await JsonRPC('url', client).call('eth_gasPrice', ['param', 'another']);

    final request = client.request!;
    expect(request.headers,
        containsPair('Content-Type', startsWith('application/json')));
  });

  test('increments request id', () async {
    final rpc = JsonRPC('url', client);
    await rpc.call('eth_gasPrice', ['param', 'another']);
    await rpc.call('eth_gasPrice', ['param', 'another']);

    final lastRequest = client.request!;
    expect(
        lastRequest.finalize().bytesToString(), completion(contains('"id":2')));
  });

  test('throws errors', () {
    final rpc = JsonRPC('url', client);
    client.nextResponse = StreamedResponse(
      Stream.value(utf8.encode('{"id": 1, "jsonrpc": "2.0", '
          '"error": {"code": 1, "message": "Message", "data": "data"}}')),
      200,
    );

    expect(rpc.call('eth_gasPrice'), throwsException);
  });
}

class MockClient extends BaseClient {
  StreamedResponse? nextResponse;
  BaseRequest? request;

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    this.request = request;
    return Future.value(nextResponse ??
        StreamedResponse(
            Stream.value(
                utf8.encode('{"id": 1, "jsonrpc": "2.0", "result": "0x1"}')),
            200));
  }
}
