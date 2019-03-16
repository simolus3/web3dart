part of 'package:web3dart/web3dart.dart';

enum _ExpensiveOperationType {
  privateKeyFromHex,
  signTransaction,
}

/// Wrapper around some potentially expensive operations so that they can
/// optionally be executed in a background isolate. This is mainly needed for
/// flutter apps where these would otherwise block the UI thread.
class _ExpensiveOperations {
  int _currentRequestId = 0;
  _Executor _executor;

  final Completer<bool> _ready = Completer();

  _ExpensiveOperations(bool inBackground) {
    if (inBackground) {
      _executor = _BackgroundIsolateExecutor();
    } else {
      _executor = _SameIsolateExecutor();
    }

    _start();
  }

  void _start() async {
    await _executor.start();
    _ready.complete(true);
  }

  void stop() {
    _executor.stop();
  }

  Future<EthPrivateKey> privateKeyFromHex(String privateKey) async {
    return await _sendOperation(
        _ExpensiveOperationType.privateKeyFromHex, privateKey) as EthPrivateKey;
  }

  Future<Uint8List> signTransaction(_SigningInput t) async {
    return await _sendOperation(_ExpensiveOperationType.signTransaction, t)
        as Uint8List;
  }

  /// Sends the request and awaits the reply from the executor.
  Future _sendOperation(_ExpensiveOperationType type, dynamic payload) async {
    await _ready.future;
    final id = _currentRequestId++;
    _executor.requests.add({
      'type': type,
      'requestId': id,
      'payload': payload,
    });

    final response =
        await _executor.responses.firstWhere((entry) => entry['id'] == id);
    return response['payload'];
  }
}

void _handleOperations(Stream<dynamic> from, Sink<dynamic> to) {
  from.listen((request) async {
    final type = request['type'] as _ExpensiveOperationType;
    final id = request['requestId'] as int;
    final payload = request['payload'];

    switch (type) {
      case _ExpensiveOperationType.privateKeyFromHex:
        final key = EthPrivateKey.fromHex(payload as String);
        await key.extractAddress();
        to.add({
          'id': id,
          'payload': key,
        });
        break;
      case _ExpensiveOperationType.signTransaction:
        final input = payload as _SigningInput;
        final signature = await _signTransaction(
          input.transaction,
          input.credentials,
          input.chainId,
        );
        to.add({
          'id': id,
          'payload': signature,
        });
        break;
    }
  });
}

/// Interface that can handle operations and asynchronously calculates them.
abstract class _Executor {
  Sink<dynamic> get requests;
  Stream<dynamic> get responses;

  FutureOr start();
  void stop();
}

class _SameIsolateExecutor implements _Executor {
  @override
  final StreamController requests = StreamController();

  final StreamController _responsesController = StreamController.broadcast();
  @override
  Stream get responses => _responsesController.stream;

  @override
  void start() {
    _handleOperations(requests.stream, _responsesController);
  }

  @override
  void stop() {
    requests.close();
    _responsesController.close();
  }
}

class _BackgroundIsolateExecutor implements _Executor {
  @override
  final StreamController requests = StreamController();

  final StreamController _responsesController = StreamController.broadcast();
  @override
  Stream get responses => _responsesController.stream;

  SendPort _sendPort;
  // ignore: unused_field
  Isolate _isolate;

  @override
  Future start() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_backgroundIsolate, receivePort.sendPort);
    receivePort.listen(_responsesController.add);

    // The first thing the isolate will do is give us a send port for further
    // configuration.
    _sendPort = await responses.first as SendPort;

    requests.stream.listen(_sendPort.send);
  }

  @override
  void stop() {
    // todo figure out how to stop _isolate
    requests.close();
    _responsesController.close();
  }
}

class _SendPortSink implements Sink {
  final SendPort _sendPort;

  _SendPortSink(this._sendPort);

  @override
  void add(data) {
    _sendPort.send(data);
  }

  @override
  void close() {}
}

void _backgroundIsolate(SendPort sendPort) {
  final port = ReceivePort();
  sendPort.send(port.sendPort);

  _handleOperations(port, _SendPortSink(sendPort));
}
