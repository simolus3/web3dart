library json_rpc;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

// ignore: one_member_abstracts
abstract class RpcService {
  /// Performs an RPC request, asking the server to execute the function with
  /// the given name and the associated parameters, which need to be encodable
  /// with the [json] class of dart:convert.
  ///
  /// When the request is successful, an [RPCResponse] with the request id and
  /// the data from the server will be returned. If not, an RPCError will be
  /// thrown. Other errors might be thrown if an IO-Error occurs.
  Future<RPCResponse> call(String function, [List<dynamic>? params]);
}

class JsonRPC extends RpcService {
  JsonRPC(this.url, this.client);

  final String url;
  final Client client;

  int _currentRequestId = 1;

  /// Performs an RPC request, asking the server to execute the function with
  /// the given name and the associated parameters, which need to be encodable
  /// with the [json] class of dart:convert.
  ///
  /// When the request is successful, an [RPCResponse] with the request id and
  /// the data from the server will be returned. If not, an RPCError will be
  /// thrown. Other errors might be thrown if an IO-Error occurs.
  @override
  Future<RPCResponse> call(String function, [List<dynamic>? params]) async {
    params ??= [];

    final requestPayload = {
      'jsonrpc': '2.0',
      'method': function,
      'params': params,
      'id': _currentRequestId++,
    };

    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestPayload),
    );

    final data = json.decode(response.body) as Map<String, dynamic>;
    final id = data['id'] as int;

    if (data.containsKey('error')) {
      final error = data['error'];

      final code = error['code'] as int;
      final message = error['message'] as String;
      final errorData = error['data'];

      throw RPCError(code, message, errorData);
    }

    final result = data['result'];
    return RPCResponse(id, result);
  }
}

/// Response from the server to an rpc request. Contains the id of the request
/// and the corresponding result as sent by the server.
class RPCResponse {
  final int id;
  final dynamic result;

  const RPCResponse(this.id, this.result);
}

/// Exception thrown when an the server returns an error code to an rpc request.
class RPCError implements Exception {
  final int errorCode;
  final String message;
  final dynamic data;

  const RPCError(this.errorCode, this.message, this.data);

  @override
  String toString() {
    return 'RPCError: got code $errorCode with msg \"$message\".';
  }
}
