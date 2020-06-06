part of 'package:web3dart/contracts.dart';

class ContractInvocation {
  final Web3Client _client;
  final DeployedContract _contract;
  final ContractFunction _function;
  List _params;

  ContractInvocation(this._client, this._contract, this._function);

  /// Creates a new [ContractInvocation] instance that will call the function with provided [args].
  ///
  /// Args can either be:
  ///  - a `Map`, where the key is the parameter name and the value is the argument value
  //// - a `List`, which behaves like [ContractFunction.encodeCall].
  ////  -a simple value, which will be wrapped in a `List` and used as a single argument.
  ContractInvocation parameters([dynamic args]) {
    assert(_params == null, 'Tried to call parameters multiple times');

    final newInvocation = ContractInvocation(_client, _contract, _function);

    if (args is Map) {
      for (final p in _function.parameters) {
        if (!args.containsKey(p.name)) {
          throw ArgumentError('Missing parameters "$p.name"');
        }
        newInvocation._params.add(args[p.name]);
      }
    } else if (args is Uint8List) {
      newInvocation._params = [args];
    } else if (args is List) {
      newInvocation._params = args;
    } else if (args != null) {
      newInvocation._params = [args];
    }

    return newInvocation;
  }

  Future<Uint8List> callRaw({EthereumAddress from, EtherAmount value}) =>
      _client
          .callRaw(
            sender: from,
            contract: _contract.address,
            data: _function.encodeCall(_params),
            value: value,
          )
          .then(hexToBytes);

  Future<List<dynamic>> call({
    EthereumAddress from,
    EtherAmount value,
  }) {
    return _client
        .callRaw(
          sender: from,
          contract: _contract.address,
          data: _function.encodeCall(_params),
          value: value,
        )
        .then(_function.decodeReturnValues);
  }

  /// Estimates the amount of gas that will be consumed when this call is sent.
  ///
  /// See also: [Web3Client.estimateGas].
  Future<int> estimateGas({
    @required EthereumAddress from,
    EtherAmount value,
  }) {
    return _client
        .estimateGas(
          sender: from,
          to: _contract.address,
          value: value,
          data: _function.encodeCall(_params),
        )
        .then((gas) => gas.toInt());
  }

  /// Creates and sends a transaction to call this contract method with arguments from [parameters].
  /// See also: [Web3Client.sendTransaction].
  Future<String> send({
    @required Credentials from,
    EtherAmount gasPrice,
    int gasLimit,
    EtherAmount value,
    int nonce = 0,
  }) async {
    final sender = await from.extractAddress();

    if (gasLimit != null && gasLimit != 0) {
      final estimateGas = await this.estimateGas(from: sender, value: value);

      if (estimateGas > gasLimit) {
        throw Exception(
            'out of gas.[estimateGas:${estimateGas.toString()}, gasLimit:${gasLimit.toString()}]');
      }
    }

    /// payload nonce
    if (nonce == 0) {
      nonce = await _client.getTransactionCount(sender);
    }

    /// sign and sent
    return _client.sendTransaction(
        from,
        Transaction.callContract(
          contract: _contract,
          function: _function,
          parameters: _params,
          from: sender,
          maxGas: gasLimit,
          value: value,
          nonce: nonce,
          gasPrice: gasPrice ?? await _client.getGasPrice(),
        ),
        fetchChainIdFromNetworkId: true);
  }
}
