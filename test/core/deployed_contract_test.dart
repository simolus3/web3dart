import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

class ERC20Contract extends DeployedContract {

    final Web3Client web3;

    @readonly Future<String> name() => invoker(web3, 'name').operator().call<String>();

    @readonly Future<int> decimals() => invoker(web3, 'decimals').operator().call();

    @readonly Future<BigInt> totalSupply() => invoker(web3,'totalSupply').operator().call();

    @readonly Future<String> symbol() => invoker(web3, 'symbol').operator().call();

    @readonly Future<BigInt> blanaceOf(EthereumAddress owner) => invoker(web3, 'balanceOf').operator().call<BigInt>();

    @readonly Future<BigInt> allowance(EthereumAddress owner, EthereumAddress spender) => invoker(web3, 'allowance').operator([owner, spender]).call(from: owner);

    @readwrite ContractInvoker transfer(EthereumAddress recipient, EtherAmount amount) => invoker(web3, 'transfer').operator([recipient, amount]);

    @readwrite ContractInvoker approve(EthereumAddress spender, EtherAmount amount) => invoker(web3, 'approve').operator([spender, amount]);

    @readwrite ContractInvoker transferFrom(EthereumAddress sender, EthereumAddress recipient) => invoker(web3, 'transferFrom').operator([sender, recipient]);

    ERC20Contract( this.web3, EthereumAddress contractAddress ) : super(
        ContractAbi.fromJson( '[' +
            /// name
            '{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},' +

            /// decimals
            '{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint"}],"payable":false,"stateMutability":"view","type":"function"},' +

            /// totalSupply
            '{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint"}],"payable":false,"stateMutability":"view","type":"function"},' +

            /// symbol
            '{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},' +

            /// function balanceOf(address account) external view returns (uint256);
            '{"constant":true,"inputs":[{"name":"account","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},' +

            /// function allowance(address owner, address spender) external view returns (uint256);
            '{"constant":true,"inputs":[{"name":"owner","type":"address"},{"name":"spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},' +

            /// function transfer(address recipient, uint256 amount) external returns (bool);
            '{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},' +

            /// function approve(address spender, uint256 amount) external returns (bool);
            '{"constant":false,"inputs":[{"name":"spender","type":"address"},{"name":"amount","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},' +

            /// function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
            '{"constant":false,"inputs":[{"name":"sender","type":"address"},{"name":"recipient","type":"address"},{"name":"amount","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},' +

            /// event Transfer(address indexed from, address indexed to, uint256 value);
            '{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"},' +

            /// event Approval(address indexed owner, address indexed spender, uint256 value);
            '{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"}' +

            ']',
            /// contract name
            'ERC20'
        ),
        contractAddress
    );
}


void main() {

  test('test ERC20 infomations', () async {

      /// use test RPC
      final web3 = Web3Client('http://127.0.0.1:8545', Client());

      final erc20 = ERC20Contract(web3, EthereumAddress.fromHex('0x6cd7595139d452F14F7dc7aa0531Ff09E7eE52C5'));

      print('Name:${await erc20.name()}');
      print('Symbol:${await erc20.symbol()}');
      print('TotalSupply:${await erc20.totalSupply()}');

  });
}
