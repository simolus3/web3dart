part of 'package:web3dart/web3dart.dart';

/// Class for sending requests over an HTTP JSON-RPC API endpoint to Ethereum
/// clients. This library won't use the accounts feature of clients to use them
/// to create transactions, you will instead have to obtain private keys of
/// accounts yourself.
class Web3Client {
  static const BlockNum _defaultBlock = BlockNum.current();

  final JsonRPC _jsonRpc;

  _ExpensiveOperations _operations;

  ///Whether errors, handled or not, should be printed to the console.
  bool printErrors = false;

  /// Starts a client that connects to a JSON rpc API, available at [url]. The
  /// [httpClient] will be used to send requests to the rpc server.
  /// If [enableBackgroundIsolate] is true (defaults to false), expensive
  /// methods like [credentialsFromPrivateKey] or [sendTransaction] will use
  /// a background isolate instead of blocking the main thread. This feature
  /// is experimental at the moment.
  Web3Client(String url, Client httpClient,
      {bool enableBackgroundIsolate = false})
      : _jsonRpc = JsonRPC(url, httpClient) {
    _operations = _ExpensiveOperations(enableBackgroundIsolate);
  }

  Future<T> _makeRPCCall<T>(String function, [List<dynamic> params]) async {
    try {
      final data = await _jsonRpc.call(function, params);
      // ignore: only_throw_errors
      if (data is Error || data is Exception) throw data;

      return data.result as T;
    } catch (e) {
      if (printErrors) print(e);

      rethrow;
    }
  }

  String _getBlockParam(BlockNum block) {
    return (block ?? _defaultBlock).toBlockParam();
  }

  /// Constructs a new [Credentials] with the provided [privateKey] by using
  /// an [EthPrivateKey]. When [enableBackgroundIsolate] is true, this will
  /// happen on a background isolate instead of blocking the main / UI thread.
  Future<Credentials> credentialsFromPrivateKey(String privateKey) {
    return _operations.privateKeyFromHex(privateKey);
  }

  /// Returns the version of the client we're sending requests to.
  Future<String> getClientVersion() {
    return _makeRPCCall('web3_clientVersion');
  }

  /// Returns the id of the network the client is currently connected to.
  ///
  /// In a non-private network, the network ids usually correspond to the
  /// following networks:
  /// 1: Ethereum Mainnet
  /// 2: Morden Testnet (deprecated)
  /// 3: Ropsten Testnet
  /// 4: Rinkeby Testnet
  /// 42: Kovan Testnet
  Future<int> getNetworkId() {
    return _makeRPCCall<String>('net_version').then(int.parse);
  }

  /// Returns true if the node is actively listening for network connections.
  Future<bool> isListeningForNetwork() {
    return _makeRPCCall('net_listening');
  }

  /// Returns the amount of Ethereum nodes currently connected to the client.
  Future<int> getPeerCount() async {
    final hex = await _makeRPCCall<String>('net_peerCount');
    return hexToInt(hex).toInt();
  }

  /// Returns the version of the Ethereum-protocol the client is using.
  Future<int> getEtherProtocolVersion() async {
    final hex = await _makeRPCCall<String>('eth_protocolVersion');
    return hexToInt(hex).toInt();
  }

  /// Returns an object indicating whether the node is currently synchronising
  /// with its network.
  ///
  /// If so, progress information is returned via [SyncInformation].
  Future<SyncInformation> getSyncStatus() async {
    final data = await _makeRPCCall<dynamic>('eth_syncing');

    if (data is Map) {
      final startingBlock = hexToInt(data['startingBlock'] as String).toInt();
      final currentBlock = hexToInt(data['currentBlock'] as String).toInt();
      final highestBlock = hexToInt(data['highestBlock'] as String).toInt();

      return SyncInformation._(startingBlock, currentBlock, highestBlock);
    } else {
      return SyncInformation._(null, null, null);
    }
  }

  Future<EthereumAddress> coinbaseAddress() async {
    final hex = await _makeRPCCall<String>('eth_coinbare');
    return EthereumAddress.fromHex(hex);
  }

  /// Returns true if the connected client is currently mining, false if not.
  Future<bool> isMining() {
    return _makeRPCCall('eth_mining');
  }

  /// Returns the amount of hashes per second the connected node is mining with.
  Future<int> getMiningHashrate() {
    return _makeRPCCall<String>('eth_hashrate')
        .then((s) => hexToInt(s).toInt());
  }

  /// Returns the amount of Ether typically needed to pay for one unit of gas.
  ///
  /// Although not strictly defined, this value will typically be a sensible
  /// amount to use.
  Future<EtherAmount> getGasPrice() async {
    final data = await _makeRPCCall<String>('eth_gasPrice');

    return EtherAmount.fromUnitAndValue(EtherUnit.wei, hexToInt(data));
  }

  /// Returns the number of the most recent block on the chain.
  Future<int> getBlockNumber() {
    return _makeRPCCall<String>('eth_blockNumber')
        .then((s) => hexToInt(s).toInt());
  }

  /// Gets the balance of the account with the specified address.
  ///
  /// This function allows specifying a custom block mined in the past to get
  /// historical data. By default, [BlockNum.current] will be used.
  Future<EtherAmount> getBalance(EthereumAddress address, {BlockNum atBlock}) {
    final blockParam = _getBlockParam(atBlock);

    return _makeRPCCall<String>('eth_getBalance', [address.hex, blockParam])
        .then((data) {
      return EtherAmount.fromUnitAndValue(EtherUnit.wei, hexToInt(data));
    });
  }

  /// Gets an element from the storage of the contract with the specified
  /// [address] at the specified [position].
  /// See https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getstorageat for
  /// more details.
  /// This function allows specifying a custom block mined in the past to get
  /// historical data. By default, [BlockNum.current] will be used.
  Future<Uint8List> getStorage(EthereumAddress address, BigInt position,
      {BlockNum atBlock}) {
    final blockParam = _getBlockParam(atBlock);

    return _makeRPCCall<String>('eth_getStorageAt', [
      address.hex,
      '0x${position.toRadixString(16)}',
      blockParam
    ]).then(hexToBytes);
  }

  /// Gets the amount of transactions issued by the specified [address].
  ///
  /// This function allows specifying a custom block mined in the past to get
  /// historical data. By default, [BlockNum.current] will be used.
  Future<int> getTransactionCount(EthereumAddress address, {BlockNum atBlock}) {
    final blockParam = _getBlockParam(atBlock);

    return _makeRPCCall<String>(
            'eth_getTransactionCount', [address.hex, blockParam])
        .then((hex) => hexToInt(hex).toInt());
  }

  /// Returns the information about a transaction requested by transaction hash
  /// [transactionHash].
  Future<TransactionInformation> getTransactionByHash(String transactionHash) {
    return _makeRPCCall<Map<String, dynamic>>(
            'eth_getTransactionByHash', [transactionHash])
        .then((s) => TransactionInformation.fromMap(s));
  }

  /// Gets the code of a contract at the specified [address]
  ///
  /// This function allows specifying a custom block mined in the past to get
  /// historical data. By default, [BlockNum.current] will be used.
  Future<Uint8List> getCode(EthereumAddress address, {BlockNum atBlock}) {
    return _makeRPCCall<String>(
        'eth_getCode', [address.hex, _getBlockParam(atBlock)]).then(hexToBytes);
  }

  /// Signs the given transaction using the keys supplied in the [cred]
  /// object to upload it to the client so that it can be executed.
  ///
  /// Returns a hash of the transaction which, after the transaction has been
  /// included in a mined block, can be used to obtain detailed information
  /// about the transaction.
  Future<String> sendTransaction(Credentials cred, Transaction transaction,
      {int chainId = 1, bool fetchChainIdFromNetworkId = false}) async {
    final signingInput = await _fillMissingData(
      credentials: cred,
      transaction: transaction,
      chainId: chainId,
      loadChainIdFromNetwork: fetchChainIdFromNetworkId,
      client: this,
    );

    final signed = await _operations.signTransaction(signingInput);

    return _makeRPCCall('eth_sendRawTransaction',
        [bytesToHex(signed, include0x: true, padToEvenLength: true)]);
  }

  /*
  /// Executes the transaction, which should be calling a method in a smart
  /// contract deployed on the blockchain, without modifying any state.
  ///
  /// For method calls that don't write to the blockchain or otherwise change
  /// its state, the connected client can compute the call locally and return
  /// the given data without consuming any gas that would be required to
  /// calculate this call if it was included in a mined block.
  /// This function allows specifying a custom block mined in the past to get
  /// historical data. By default, [BlockNum.current] will be used.
  Future<List<dynamic>> call(
      Credentials cred, RawTransaction transaction, ContractFunction decoder,
      {BlockNum atBlock, int chainId}) {
    String intToHex(dynamic d) => numbers.toHex(d, pad: true, include0x: true);

    final data = {
      'from': cred.address.hex,
      'to': intToHex(transaction.to),
      'data': numbers.bytesToHex(transaction.data, include0x: true),
    };

    return _makeRPCCall<String>('eth_call', [data, _getBlockParam(atBlock)])
        .then((data) {
      return decoder.decodeReturnValues(data);
    });
  }*/
}
