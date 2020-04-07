part of 'package:web3dart/metamask.dart';

class MetaMask implements RpcService {
  static bool get isSupported {
    return context.hasProperty('ethereum');
  }

  final JsObject _ethereum;

  MetaMask._(this._ethereum);

  MetaMask() : this._(context['ethereum'] as JsObject);

  /// Requests the user provides an ethereum address to be identified by.
  ///
  /// This method should only be called as a response to user interaction and
  /// not on page load.
  Future<List<MetaMaskAccount>> enable() {
    return _send('eth_requestAccounts', []).then((value) {
      return (value['result'] as List)
          .map((e) => MetaMaskAccount._(this, e as String))
          .toList();
    });
  }

  @override
  Future<RPCResponse> call(String function, [List<dynamic> params]) {
    return _send(function, params).then((raw) {
      return RPCResponse(0, raw['result']);
    });
  }

  Future<dynamic> _send(String method, List<dynamic> params, [String from]) {
    final requestObj = JsObject(context['Object'] as JsFunction);
    requestObj['method'] = method;
    requestObj['params'] = params;
    if (from != null) requestObj['from'] = from;

    final completer = Completer<dynamic>();

    final callback = allowInterop((dynamic error, dynamic response) {
      if (error != null) {
        completer.completeError(error);
      } else {
        completer.complete(response);
      }
    });

    _ethereum.callMethod('send', [requestObj, callback]);

    return completer.future;
  }
}

class MetaMaskAccount extends Credentials {
  final MetaMask _handle;
  final String _rawHexAddress;

  /// The [EthereumAddress] associated with this MetaMask account.
  final EthereumAddress address;

  MetaMaskAccount._(this._handle, this._rawHexAddress)
      : address = EthereumAddress.fromHex(_rawHexAddress);

  @override
  Future<EthereumAddress> extractAddress() => Future.value(address);

  @override
  Future<MsgSignature> signToSignature(Uint8List payload, {int chainId}) {
    throw UnsupportedError('MetaMask does not support signing arbitrary data');
  }

  @override
  String toString() {
    return 'MetaMask@$_rawHexAddress';
  }
}
