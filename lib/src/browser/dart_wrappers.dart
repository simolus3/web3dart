import 'dart:async';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import '../../credentials.dart';
import '../../json_rpc.dart';
import 'credentials.dart';
import 'javascript.dart';

/// This extension provides Dart methods around the raw [Ethereum] JavaScript
/// object.
///
/// Extensions include [request] to turn request promises into Dart futures or
/// [on] to turn JavaScript event handlers into convenient Dart streams.
/// To use the raw ethereum client in a high-level `Web3Client`, use
/// [asRpcService].
extension DartEthereum on Ethereum {
  /// Turns this raw client into an rpc client that can be used to create a
  /// `Web3Client`:
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   final eth = window.ethereum;
  ///   if (eth == null) {
  ///     print('MetaMask is not available');
  ///     return;
  ///   }
  ///
  ///   final client = Web3Client.custom(eth.asRpcService());
  /// }
  /// ```
  RpcService asRpcService() => _MetaMaskRpcService(this);

  /// Sends a raw rpc request using the injected Ethereum client.
  ///
  /// If possible, prefer using [asRpcService] to construct a high-level client
  /// instead.
  ///
  /// See also:
  ///  - the rpc documentation under https://docs.metamask.io/guide/rpc-api.html
  Future<dynamic> rawRequest(String method, {Object? params}) {
    // No, this can't be simplified. Metamask wants `params` to be undefined.
    final args = params == null
        ? RequestArguments(method: method)
        : RequestArguments(method: method, params: params);
    return promiseToFuture(request(args));
  }

  /// Asks the user to select an account and give your application access to it.
  Future<CredentialsWithKnownAddress> requestAccount() {
    return rawRequest('eth_requestAccounts').then((res) {
      return MetaMaskCredentials((res as List).single as String, this);
    });
  }

  /// Creates a stream of raw ethereum events.
  ///
  /// The returned stream is a broadcast stream, meaning that it can be listened
  /// to multiple times.
  ///
  /// See also:
  ///  - https://docs.metamask.io/guide/ethereum-provider.html#events
  Stream<dynamic> stream(String eventName) {
    return _EventStream(this, eventName);
  }

  /// A broadcast stream emitting values when the selected chain is changed by
  /// the user.
  Stream<int> get chainChanged => stream('chainChanged').cast();
}

class _MetaMaskRpcService extends RpcService {
  final Ethereum _ethereum;

  _MetaMaskRpcService(this._ethereum);

  @override
  Future<RPCResponse> call(String function, [List? params]) {
    return _ethereum.rawRequest(function, params: params).then((res) {
      return RPCResponse(0, res);
    });
  }
}

class _EventStream extends Stream<dynamic> {
  final Ethereum _client;
  final String _eventName;

  _EventStream(this._client, this._eventName);

  @override
  bool get isBroadcast => true;

  @override
  Stream asBroadcastStream(
      {void Function(StreamSubscription subscription)? onListen,
      void Function(StreamSubscription subscription)? onCancel}) {
    return this;
  }

  @override
  StreamSubscription listen(void Function(dynamic event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final sub = _EventStreamSubscription(_client, _eventName, onData);
    // onError, onDone and cancelOnErrors are not applicable here because event
    // streams are infinite and don't transport errors.
    return sub;
  }
}

class _EventStreamSubscription extends StreamSubscription<dynamic> {
  final Ethereum _client;
  final String _eventName;
  Function(dynamic)? _onData;

  Function? _jsCallback;
  int _activePauseRequests = 0;
  bool _isCancelled = false;

  _EventStreamSubscription(
      this._client, this._eventName, Function(dynamic)? onData) {
    if (_onData != null) {
      _onData = Zone.current.bindUnaryCallback(onData!);
    }
    _resumeIfNecessary();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) {
    // Conceptionally, this should return a future completing for onDone or
    // onError. Since neither can happen for an event stream, we just never
    // complete
    return Completer<Never>().future;
  }

  @override
  Future<void> cancel() {
    if (!_isCancelled) {
      _stopListening();
      _onData = null;
      _isCancelled = true;
    }

    return Future.value();
  }

  @override
  bool get isPaused => _activePauseRequests > 0;

  @override
  void onData(void Function(dynamic data)? handleData) {
    if (_isCancelled) {
      throw StateError('Subscription has been cancelled');
    }

    // Remove the current listener, then attach the new one
    _stopListening();
    _onData =
        handleData == null ? null : Zone.current.bindUnaryCallback(handleData);
    _resumeIfNecessary();
  }

  @override
  void onDone(void Function()? handleDone) {
    // Nothing to do, event streams are never done
  }

  @override
  void onError(Function? handleError) {
    // Nothing to do, event streams don't emit errors
  }

  @override
  void pause([Future<void>? resumeSignal]) {
    if (_isCancelled) return;

    _activePauseRequests++;
    _stopListening();
    resumeSignal?.whenComplete(resume);
  }

  @override
  void resume() {
    if (_isCancelled || !isPaused) return;
    _activePauseRequests--;
    _resumeIfNecessary();
  }

  void _resumeIfNecessary() {
    if (_onData != null && !isPaused) {
      final cb = _jsCallback = allowInterop(_onData!);
      _client.on(_eventName, cb);
    }
  }

  void _stopListening() {
    final callback = _jsCallback;
    if (callback != null) {
      _client.removeListener(_eventName, callback);
    }
  }
}
