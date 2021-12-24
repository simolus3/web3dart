import 'dart:convert';

import 'package:async/async.dart';
import 'package:http/http.dart';
import 'package:test/test.dart';

class MockClient extends BaseClient {
  static final _jsonUtf8 = json.fuse(utf8);

  final Object? Function(String method, Object? payload) handler;

  MockClient(this.handler);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final data = await _jsonUtf8.decoder.bind(request.finalize()).first;

    if (data is! Map) {
      fail('Invalid request, expected JSON map');
    }

    if (data['jsonrpc'] != '2.0') {
      fail('Expected request to contain correct jsonrpc key');
    }

    final id = data['id'];
    final method = data['method'] as String;
    final params = data['params'];

    final response = Result(() => handler(method, params));

    return StreamedResponse(
      _jsonUtf8.encoder.bind(
        Stream.value(
          {
            'jsonrpc': '2.0',
            if (response is ValueResult) 'result': response.value,
            if (response is ErrorResult)
              'error': {
                'code': -1,
                'message': '${response.error}',
              },
            'id': id,
          },
        ),
      ),
      200,
    );
  }
}
