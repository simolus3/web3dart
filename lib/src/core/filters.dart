part of 'package:web3dart/web3dart.dart';

class _FilterCreationParams {
  final String method;
  final List<dynamic> params;

  _FilterCreationParams(this.method, this.params);
}

class _PubSubCreationParams {
  final List<dynamic> params;

  _PubSubCreationParams(this.params);
}

abstract class _Filter<T> {
  _FilterCreationParams create();
  _PubSubCreationParams createPubSub();
  T parseChanges(dynamic log);
}

class _NewBlockFilter extends _Filter<String> {
  @override
  _FilterCreationParams create() {
    return _FilterCreationParams('eth_newBlockFilter', []);
  }

  @override
  String parseChanges(log) {
    return log as String;
  }

  @override
  _PubSubCreationParams createPubSub() {
    // the pub-sub subscription for new blocks isn't universally supported by
    // ethereum nodes, so let's not implement it just yet.
    return null;
  }
}

class _PendingTransactionsFilter extends _Filter<String> {
  @override
  _FilterCreationParams create() {
    return _FilterCreationParams('eth_newPendingTransactionFilter', []);
  }

  @override
  String parseChanges(log) {
    return log as String;
  }

  @override
  _PubSubCreationParams createPubSub() {
    // TODO: implement createPubSub
    return null;
  }
}

/// Options for event filters created with [Web3Client.events].
class FilterOptions {
  /// The earliest block which should be considered for this filter. Optional,
  /// the default value is [BlockNum.current].
  ///
  /// Use [BlockNum.current] for the last mined block or
  /// [BlockNum.pending]  for not yet mined transactions.
  final BlockNum fromBlock;

  /// The last block which should be considered for this filter. Optional, the
  /// default value is [BlockNum.current].
  ///
  /// Use [BlockNum.current] for the last mined block or
  /// [BlockNum.pending]  for not yet mined transactions.
  final BlockNum toBlock;

  /// The optional address to limit this filter to. If not null, only logs
  /// emitted from the contract at [address] will be considered. Otherwise, all
  /// log events will be reported.
  final EthereumAddress address;

  /// The topics that must be present in the event to be included in this
  /// filter. The topics must be represented as a hexadecimal value prefixed
  /// with "0x". The encoding must have an even number of digits.
  ///
  /// Topics are order-dependent. A transaction with a log with topics \[A, B\]
  /// will be matched by the following topic filters:
  /// - \[\], which matches anything
  /// - \[A\], which matches "A" in the first position and anything after
  /// - \[null, B\], which matches logs that have anything in their first
  ///   position, B in their second position and anything after
  /// - \[A, B\], which matches A in first position, B in second position (and
  /// anything after)
  /// - \[\[A, B\], \[A, B\]\]: Matches (A or B) in first position AND (A or B)
  /// in second position (and anything after).
  ///
  /// The events sent by solidity contracts are encoded like this: The first
  /// topic is the hash of the event signature (except for anonymous events).
  /// All further topics are the encoded values of the indexed parameters of the
  /// event. See https://solidity.readthedocs.io/en/develop/contracts.html#events
  /// for a detailed description.
  final List<List<String>> topics;

  FilterOptions({this.fromBlock, this.toBlock, this.address, this.topics});

  FilterOptions.events(
      {@required DeployedContract contract,
      @required ContractEvent event,
      this.fromBlock,
      this.toBlock})
      : address = contract.address,
        topics = [
          [bytesToHex(event.signature, padToEvenLength: true, include0x: true)]
        ];
}

/// A log event emitted in a transaction.
class FilterEvent {
  /// Whether the log was removed, due to a chain reorganization. False if it's
  /// a valid log.
  final bool removed;

  /// Log index position in the block. `null` when the transaction which caused
  /// this log has not yet been mined.
  final int logIndex;

  /// Transaction index position in the block.
  /// `null` when the transaction which caused this log has not yet been mined.
  final int transactionIndex;

  /// Hash of the transaction which caused this log. `null` when it's pending.
  final String transactionHash;

  /// Hash of the block where this log was in. `null` when it's pending.
  final String blockHash;

  /// The block number of the block where this log was in. `null` when it's
  /// pending.
  final int blockNum;

  /// The address (of the smart contract) from which this log originated.
  final EthereumAddress address;

  /// The data blob of this log, hex-encoded.
  ///
  /// For solidity events, this contains all non-indexed parameters of the
  /// event.
  final String data;

  /// The topics of this event, hex-encoded.
  ///
  /// For solidity events, the first topic is a hash of the event signature
  /// (except for anonymous events). All further topics are the encoded
  /// values of indexed parameters.
  final List<String> topics;

  FilterEvent(
      {this.removed,
      this.logIndex,
      this.transactionIndex,
      this.transactionHash,
      this.blockHash,
      this.blockNum,
      this.address,
      this.data,
      this.topics});

  @override
  String toString() {
    return 'FilterEvent('
        'removed=$removed,'
        'logIndex=$logIndex,'
        'transactionIndex=$transactionIndex,'
        'transactionHash=$transactionHash,'
        'blockHash=$blockHash,'
        'blockNum=$blockNum,'
        'address=$address,'
        'data=$data,'
        'topics=$topics'
        ')';
  }
}

class _EventFilter extends _Filter<FilterEvent> {
  final FilterOptions options;

  _EventFilter(this.options);

  @override
  _FilterCreationParams create() {
    return _FilterCreationParams('eth_newFilter', [_createParamsObject(true)]);
  }

  @override
  _PubSubCreationParams createPubSub() {
    return _PubSubCreationParams([
      'logs',
      _createParamsObject(false),
    ]);
  }

  dynamic _createParamsObject(bool includeFromAndTo) {
    final encodedOptions = <String, dynamic>{};
    if (options.fromBlock != null && includeFromAndTo) {
      encodedOptions['fromBlock'] = options.fromBlock.toBlockParam();
    }
    if (options.toBlock != null && includeFromAndTo) {
      encodedOptions['toBlock'] = options.toBlock.toBlockParam();
    }
    if (options.address != null) {
      encodedOptions['address'] = options.address.hex;
    }
    if (options.topics != null) {
      encodedOptions['topics'] = options.topics;
    }

    return encodedOptions;
  }

  @override
  FilterEvent parseChanges(log) {
    return FilterEvent(
      removed: log['removed'] as bool ?? false,
      logIndex: hexToInt(log['logIndex'] as String).toInt(),
      transactionIndex: hexToInt(log['logIndex'] as String).toInt(),
      transactionHash: log['transactionHash'] as String,
      blockHash: log['blockHash'] as String,
      blockNum: hexToInt(log['blockNumber'] as String).toInt(),
      address: EthereumAddress.fromHex(log['address'] as String),
      data: log['data'] as String,
      topics: (log['topics'] as List).cast<String>(),
    );
  }
}

const _pingDuration = Duration(seconds: 2);

class _FilterEngine {
  final List<_InstantiatedFilter> _filters = [];
  final Web3Client _client;

  JsonRPC get _rpc => _client._jsonRpc;

  Timer _ticker;
  bool _isRefreshing = false;
  bool _clearingBecauseSocketClosed = false;

  final List<Future> _pendingUnsubcriptions = [];

  _FilterEngine(this._client);

  Stream<T> addFilter<T>(_Filter<T> filter) {
    final pubSubParams = filter.createPubSub();
    final pubSubAvailable = _client.socketConnector != null;
    final supportsPubSub = pubSubParams != null && pubSubAvailable;

    _InstantiatedFilter<T> instantiated;
    instantiated = _InstantiatedFilter(filter, supportsPubSub, () {
      _pendingUnsubcriptions.add(uninstall(instantiated));
    });
    _filters.add(instantiated);

    if (instantiated.isPubSub) {
      _registerToPubSub(instantiated, pubSubParams);
    } else {
      _registerToAPI(instantiated);
      _startTicking();
    }

    return instantiated._controller.stream;
  }

  void _registerToAPI(_InstantiatedFilter filter) async {
    final request = filter.filter.create();

    try {
      final response = await _rpc.call(request.method, request.params);
      filter.id = response.result as String;
    } on RPCError catch (e, s) {
      filter._controller.addError(e, s);
      await filter._controller.close();
      _filters.remove(filter);
    }
  }

  void _registerToPubSub(
      _InstantiatedFilter filter, _PubSubCreationParams params) async {
    final peer = _client._connectWithPeer();

    try {
      final response = await peer.sendRequest('eth_subscribe', params.params);
      filter.id = response as String;
    } on rpc.RpcException catch (e, s) {
      filter._controller.addError(e, s);
      await filter._controller.close();
      _filters.remove(filter);
    }
  }

  void _startTicking() {
    _ticker ??= Timer.periodic(_pingDuration, (_) => _refreshFilters());
  }

  void _refreshFilters() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final filterSnapshot = List.of(_filters);

      for (var filter in filterSnapshot) {
        final updatedData =
            await _rpc.call('eth_getFilterChanges', [filter.id]);

        for (var payload in updatedData.result) {
          if (!filter._controller.isClosed) {
            _parseAndAdd(filter, payload);
          }
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  void handlePubSubNotification(rpc.Parameters params) {
    final id = params['subscription'].asString;
    final result = params['result'].value;

    final filter = _filters.singleWhere((f) => f.isPubSub && f.id == id,
        orElse: () => null);
    _parseAndAdd(filter, result);
  }

  void handleConnectionClosed() {
    try {
      _clearingBecauseSocketClosed = true;
      final pubSubFilters = _filters.where((f) => f.isPubSub).toList();

      for (var filter in pubSubFilters) {
        uninstall(filter);
      }
    } finally {
      _clearingBecauseSocketClosed = false;
    }
  }

  void _parseAndAdd(_InstantiatedFilter filter, dynamic payload) {
    final parsed = filter.filter.parseChanges(payload);
    filter._controller.add(parsed);
  }

  Future uninstall(_InstantiatedFilter filter) async {
    await filter._controller.close();
    _filters.remove(filter);

    if (filter.isPubSub && !_clearingBecauseSocketClosed) {
      final connection = _client._connectWithPeer();
      await connection.sendRequest('eth_unsubscribe', [filter.id]);
    } else {
      await _rpc.call('eth_uninstallFilter', [filter.id]);
    }
  }

  Future dispose() async {
    _ticker?.cancel();
    final remainingFilters = List.of(_filters);

    await Future.forEach(remainingFilters, uninstall);
    await Future.wait(_pendingUnsubcriptions);

    _pendingUnsubcriptions.clear();
  }
}

class _InstantiatedFilter<T> {
  /// The id of this filter. This value will be obtained from the API after the
  /// filter has been set up and is `null` before that.
  String id;
  final _Filter<T> filter;

  /// Whether the filter is listening on a websocket connection.
  final bool isPubSub;

  final StreamController<T> _controller;

  _InstantiatedFilter(this.filter, this.isPubSub, Function() onCancel)
      : _controller = StreamController(onCancel: onCancel);
}
