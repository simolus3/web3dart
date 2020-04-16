part of 'package:web3dart/contracts.dart';

class ContractInvocation {
  final Web3Client _client;
  final DeployedContract _contract;
  final ContractFunction _function;
  List _params;

  ContractInvocation._(this._client, this._contract, this._function);

  /// Creates a new [ContractInvocation] instance that will call the function with provided [args].
  ///
  /// Args can either be:
  ///  - a `Map`, where the key is the parameter name and the value is the argument value
  //// - a `List`, which behaves like [ContractFunction.encodeCall].
  ////  -a simple value, which will be wrapped in a `List` and used as a single argument.
  ContractInvocation parameters([dynamic args]) {
    assert(_params == null, 'Tried to call parameters multiple times');
    if (args is Map) {
      for (final p in function.parameters) {
        if (!args.containsKey(p.name)) {
          throw ArgumentError('Missing parameters "$p.name"');
        }
        _params.add(args[p.name]);
      }
    } else if (args is List) {
      _params = args;
    } else if (args != null) {
      _params = [args];
    }

    return this;
  }

  Future<T> call<T>({
    EthereumAddress from,
    EtherAmount value,
  }) {
    return client
        .callRaw(
      sender: from,
      contract: contract.address,
      data: function.encodeCall(_params),
      value: value,
    )
        .then((rawRsp) {
      final r = function.decodeReturnValues(rawRsp);

      if (T is Map) {
        Map ret;

        for (var i = 0; i < function.outputs.length; i++) {
          final output = function.outputs[i];

          ret[i] = r[i];

          if (output.name != null && output.name.isNotEmpty) {
            ret[output.name] = r[i];
          }
        }

        return Future.value(ret as T);
      } else if (T is List) {
        return Future.value(function.decodeReturnValues(rawRsp) as T);
      } else {
        return Future.value(r.first as T);
      }
    });
  }

  /// Estimates the amount of gas that will be consumed when this call is sent.
  ///
  /// See also: [Web3Client.estimateGas].
  Future<int> estimateGas({
    @required EthereumAddress from,
    EtherAmount value,
  }) {
    return client
        .estimateGas(
      sender: from,
      to: contract.address,
      value: value,
      data: function.encodeCall(_params),
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
      nonce = await client.getTransactionCount(sender);
    }

    /// sign and sent
    return client.sendTransaction(
        from,
        Transaction.callContract(
          contract: contract,
          function: function,
          parameters: _params,
          from: sender,
          maxGas: gasLimit,
          value: value,
          nonce: nonce,
          gasPrice: gasPrice ?? await client.getGasPrice(),
        ),
        fetchChainIdFromNetworkId: true);
  }
}
