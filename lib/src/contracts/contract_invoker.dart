part of 'package:web3dart/contracts.dart';

class ExternalABI {

    final String reason;

    const ExternalABI([this.reason = '']);
}

const readonly = ExternalABI('external pure or view function');

const readwrite = ExternalABI('external function');

const readwritePayable = ExternalABI('external payable function');

class ContractInvoker {

    final Web3Client client;
    final DeployedContract contract;
    final ContractFunction function;
    List params;

    ContractInvoker(this.client, this.contract, this.function, [this.params]);

    ContractInvoker operator ([List args]) {
        params = args;
        return this;
    }

    Future<T> call<T>({
        EthereumAddress from,
        EtherAmount value,
    }) {
        return client.callRaw(
            sender: from,
            contract: contract.address,
            data: function.encodeCall(params),
            value: value,
        ).then( (rawRsp) {

            final r = function.decodeReturnValues(rawRsp);

            if ( T is Map ) {

                Map ret;

                print('Output:${function.outputs.toString()}');

                for ( var i = 0; i < function.outputs.length; i++ ) {

                    final output = function.outputs[i];

                    ret[i] = r[i];

                    if ( output.name != null && output.name.isNotEmpty ) {
                        ret[output.name] = r[i];
                    }
                }

                return Future.value(ret as T);

            } else if ( T is List ) {
                return Future.value( function.decodeReturnValues(rawRsp) as T );
            } else {
                return Future.value( r.first as T );
            }

        });
    }

    Future<int> estimateGas({
        @required EthereumAddress from,
        EtherAmount value,
    }) {
        return client.estimateGas(
            sender: from,
            to: contract.address,
            value: value,
            data: function.encodeCall(params),
        ).then( (gas) {
            return Future.value(gas.toInt());
        });
    }

    Future<String> send({
        @required Credentials from,
        @required int gasPrice,
        int gasLimit = 10000000,
        EtherAmount value,
        int nonce,
    }) async {

        final sender = await from.extractAddress();

        final estimateGas = await this.estimateGas(from: sender, value: value);

        if ( estimateGas > gasLimit ) {
            throw Exception('out of gas.[estimateGas:${estimateGas.toString()}, gasLimit:${gasLimit.toString()}]');
        }

        /// payload nonce
        if ( nonce == 0 ) {
            nonce = await client.getTransactionCount(sender);
        }

        /// 发送交易
        return client.sendTransaction(from, Transaction.callContract(
            contract: contract,
            function: function,
            parameters: params,
            from: sender,
            maxGas: gasLimit,
            value: value,
            nonce: nonce
        ));
    }
}
