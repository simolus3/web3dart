import 'package:web3dart/web3dart.dart';

class Token {
  Token(this.contractAddress, this.client, this.privateKey, {this.chainId = 1})
      : contract = DeployedContract(
            ContractAbi.fromJson(
                '[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor","signature":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event","signature":"0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"},{"constant":false,"inputs":[{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"name":"sendCoin","outputs":[{"name":"sufficient","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x90b98a11"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"getBalanceInEth","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x7bd703e8"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"getBalance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function","signature":"0xf8b2cb4f"}]',
                'Token'),
            contractAddress);

  final EthereumAddress contractAddress;

  final Web3Client client;

  final DeployedContract contract;

  final String privateKey;

  final int chainId;

  Future<String> sendCoin(EthereumAddress receiver, BigInt amount) async {
    final function = contract.function('sendCoin');
    final params = [receiver, amount];
    final credentials = await client.credentialsFromPrivateKey(privateKey);
    final transaction = Transaction.callContract(
        contract: contract, function: function, parameters: params);
    return _write(credentials, transaction);
  }

  Future<BigInt> getBalanceInEth(EthereumAddress addr) async {
    final function = contract.function('getBalanceInEth');
    final params = [addr];
    return await (_read(contract, function, params) as Future<BigInt>);
  }

  Future<BigInt> getBalance(EthereumAddress addr) async {
    final function = contract.function('getBalance');
    final params = [addr];
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
