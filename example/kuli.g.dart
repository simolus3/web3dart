import 'package:web3dart/web3dart.dart';

class Kuli {
  Kuli(this.contractAddress, this.client, this.privateKey, {this.chainId = 1})
      : contract = DeployedContract(
            ContractAbi.fromJson(
                '[{"inputs":[{"internalType":"uint240","name":"first","type":"uint240"},{"internalType":"uint248","name":"second","type":"uint248"}],"name":"retrieve3","outputs":[{"internalType":"string","name":"","type":"string"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"}]',
                'Kuli'),
            contractAddress);

  final EthereumAddress contractAddress;

  final Web3Client client;

  final DeployedContract contract;

  final String privateKey;

  final int chainId;

  Future<Retrieve3Response> retrieve3(uint240 first, uint248 second) async {
    final function = contract.function('retrieve3');
    final params = [first, second];
    return await (_read(contract, function, params) as Future<BigInt>);
  }

  Future<List<dynamic>> _read(DeployedContract contract,
      ContractFunction function, List<dynamic> params) async {
    return await client.call(
        contract: contract, function: function, params: params);
  }

  Future<String> _write(
      Credentials credentials, Transaction transaction) async {
    return await client.sendTransaction(credentials, transaction,
        chainId: chainId);
  }
}

class Retrieve3Response {
  Retrieve3Response(this.var1, BigInt var2, bool var3);

  final String var1;

  final BigInt var5;

  final bool var6;
}
