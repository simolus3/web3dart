//@dart=2.9
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

class Token {
  static const _abiDefinition =
      '[{"inputs":[],"payable":false,"stateMutability":"nonpayable","type":"constructor","signature":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"},{"indexed":false,"name":"_value","type":"uint256"}],"name":"Transfer","type":"event","signature":"0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"},{"constant":false,"inputs":[{"name":"receiver","type":"address"},{"name":"amount","type":"uint256"}],"name":"sendCoin","outputs":[{"name":"sufficient","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function","signature":"0x90b98a11"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"getBalanceInEth","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function","signature":"0x7bd703e8"},{"constant":true,"inputs":[{"name":"addr","type":"address"}],"name":"getBalance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function","signature":"0xf8b2cb4f"}]';
  final Web3Client client;
  final DeployedContract contract;
  final int chainId;
  Token(
      {@required this.client,
      @required EthereumAddress address,
      this.chainId = 1})
      : contract = DeployedContract(
            ContractAbi.fromJson(_abiDefinition, 'Token'), address);
}
