// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

class Token extends _i1.GeneratedContract {
  Token({required _i1.EthereumAddress address, required client, int? chainId})
      : super(
            _i1.DeployedContract(_i1.ContractAbi.fromJson(
                '[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor","signature":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event","signature":"0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"},{"constant":false,"inputs":[{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"name":"sendCoin","outputs":[{"name":"sufficient","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x90b98a11"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"getBalanceInEth","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x7bd703e8"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"getBalance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function","signature":"0xf8b2cb4f"}]',
                'Token')),
            client,
            chainId);

  Future<String> sendCoin(_i1.EthereumAddress receiver, BigInt amount,
      {required _i1.Credentials credentials}) async {
    final function = self.function('sendCoin');
    final params = ['receiver', 'amount'];
    final transaction = Transaction.callContract(
        contract: self, function: function, parameters: params);
    return write(credentials, transaction);
  }

  Future<BigInt> getBalanceInEth(_i1.EthereumAddress addr) async {
    final function = self.function('getBalanceInEth');
    final params = ['addr'];
    final response = await read(self, function, params);
    return (response[0] as BigInt);
  }

  Future<BigInt> getBalance(_i1.EthereumAddress addr) async {
    final function = self.function('getBalance');
    final params = ['addr'];
    final response = await read(self, function, params);
    return (response[0] as BigInt);
  }
}
