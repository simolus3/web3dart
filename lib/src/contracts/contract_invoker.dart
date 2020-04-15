part of 'package:web3dart/contracts.dart';

class ContractInvocation {
  final Web3Client client;
  final DeployedContract contract;
  final ContractFunction function;
  List _params;

  ContractInvocation(this.client, this.contract, this.function);

  ContractInvocation parameters([dynamic args]) {
    if (args is Map) {
      for (final p in function.parameters) {
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
        .then((gas) {
      return Future.value(gas.toInt());
    });
  }

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
