import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

class ERC20Contract extends DeployedContract {

    final Web3Client web3;

    @readonly Future<String> name() => invoker(web3, 'name').call<String>();

    @readonly Future<BigInt> decimals() => invoker(web3, 'decimals').call();

    @readonly Future<BigInt> totalSupply() => invoker(web3,'totalSupply').call();

    @readonly Future<String> symbol() => invoker(web3, 'symbol').call();

    @readonly Future<BigInt> blanaceOf(EthereumAddress owner) => invoker(web3, 'balanceOf').parameters(owner).call<BigInt>();

    @readonly Future<BigInt> allowance(EthereumAddress owner, EthereumAddress spender) => invoker(web3, 'allowance').parameters([owner, spender]).call(from: owner);

    @readwrite ContractInvocation transfer(EthereumAddress recipient, BigInt amount) => invoker(web3, 'transfer').parameters([recipient, amount]);

    @readwrite ContractInvocation approve;

    @readwrite ContractInvocation transferFrom;

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
      final web3 = Web3Client('http://testrpc:4001', Client());

      final erc20 = ERC20Contract(web3, EthereumAddress.fromHex('0xf4A21353da36389a924ab144DcC694BEf1B1d0F2'));

      /// test address
      final account = EthPrivateKey.fromHex('0x9a28e3c832827b79e856b1868289ad99dbdab3f8cf4e7e9d1932069afe9e0fd3');
      final fromAddress = await account.extractAddress();
      final toAddress = EthereumAddress.fromHex('0xB661639fb5A9C5F18E37aB567FCd65B8890D1E3e');

      print('NetworkID:${await web3.getNetworkId()}');
      print('Name: ${await erc20.name()}');
      print('Symbol: ${await erc20.symbol()}');
      print('Decimals: ${await erc20.decimals()}');
      print('TotalSupply: ${EtherAmount.fromWei(await erc20.totalSupply()).getValueInUnit(EtherUnit.ether)}');

      final invoker = erc20.transfer(
          toAddress,
          EtherAmount.fromEther(1).getInWei
      );

      print('Begin transfer: 0xf5DdA759346F8d185e04D14D4457729394D3ce00 -> 0xB661639fb5A9C5F18E37aB567FCd65B8890D1E3e : 1.00 ${await erc20.name()}');
      print('  > EstimateGas: ${await invoker.estimateGas(from: fromAddress)}');
      print('  > TryCallReceipt: ${await invoker.call(from: fromAddress)}');

      final txHash = await invoker.send(from: account);
      print('  > SentAndHash:${txHash.toString()}');

      print('Balnace:');
      print('0xf5DdA759346F8d185e04D14D4457729394D3ce00: ${EtherAmount.fromWei(await erc20.blanaceOf(fromAddress)).getValueInUnit(EtherUnit.ether)}');
      print('0xB661639fb5A9C5F18E37aB567FCd65B8890D1E3e: ${EtherAmount.fromWei(await erc20.blanaceOf(toAddress)).getValueInUnit(EtherUnit.ether)}');

      // print( (await web3.getTransactionByHash(txHash)).toString() );
  });
}
