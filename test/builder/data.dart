const testCases = <String, String>{
'''
[
    {
      "inputs": [
        {
          "internalType": "uint240",
          "name": "first",
          "type": "uint240"
        },
        {
          "internalType": "uint248",
          "name": "second",
          "type": "uint248"
        }
      ],
      "name": "retrieve3",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        },
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        },
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "pure",
      "type": "function"
    }
]''':
'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(
            _i1.DeployedContract(
                _i1.ContractAbi.fromJson(
                    '[{"inputs":[{"internalType":"uint240","name":"first","type":"uint240"},{"internalType":"uint248","name":"second","type":"uint248"}],"name":"retrieve3","outputs":[{"internalType":"string","name":"","type":"string"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"}]',
                    'Contract'),
                address),
            client,
            chainId);

  Future<Retrieve3> retrieve3(BigInt first, BigInt second) async {
    final function = self.function('retrieve3');
    final params = [first, second];
    final response = await read(function, params);
    return Retrieve3(response);
  }
}

class Retrieve3 {
  Retrieve3(List<dynamic> response)
      : var1 = (response[0] as String),
        var2 = (response[1] as BigInt),
        var3 = (response[2] as bool);

  final String var1;

  final BigInt var2;

  final bool var3;
}
''',
'''
[
    {
      "inputs": [],
      "name": "giveMeHello",
      "outputs": [
        {
          "internalType": "string",
          "name": "message",
          "type": "string"
        },
        {
          "internalType": "uint256",
          "name": "num1",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "num2",
          "type": "uint256"
        }
      ],
      "stateMutability": "pure",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "retrieve",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "num",
          "type": "uint256"
        }
      ],
      "name": "store",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
]''':
'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(
            _i1.DeployedContract(
                _i1.ContractAbi.fromJson(
                    '[{"inputs":[],"name":"giveMeHello","outputs":[{"internalType":"string","name":"message","type":"string"},{"internalType":"uint256","name":"num1","type":"uint256"},{"internalType":"uint256","name":"num2","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"retrieve","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"num","type":"uint256"}],"name":"store","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
                    'Contract'),
                address),
            client,
            chainId);

  Future<GiveMeHello> giveMeHello() async {
    final function = self.function('giveMeHello');
    final params = [];
    final response = await read(function, params);
    return GiveMeHello(response);
  }

  Future<BigInt> retrieve() async {
    final function = self.function('retrieve');
    final params = [];
    final response = await read(function, params);
    return (response[0] as BigInt);
  }

  Future<String> store(BigInt num,
      {required _i1.Credentials credentials}) async {
    final function = self.function('store');
    final params = [num];
    final transaction = _i1.Transaction.callContract(
        contract: self, function: function, parameters: params);
    return write(credentials, transaction);
  }
}

class GiveMeHello {
  GiveMeHello(List<dynamic> response)
      : message = (response[0] as String),
        num1 = (response[1] as BigInt),
        num2 = (response[2] as BigInt);

  final String message;

  final BigInt num1;

  final BigInt num2;
}
''',
'''
[
    {
        "inputs": [],
        "name": "test",
        "outputs": [
            {
                "internalType": "string[][6][3]",
                "name": "",
                "type": "string[][6][3]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
]''':
'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(
            _i1.DeployedContract(
                _i1.ContractAbi.fromJson(
                    '[{"inputs":[],"name":"test","outputs":[{"internalType":"string[][6][3]","name":"","type":"string[][6][3]"}],"stateMutability":"view","type":"function"}]',
                    'Contract'),
                address),
            client,
            chainId);

  Future<List<List<List<String>>>> test() async {
    final function = self.function('test');
    final params = [];
    final response = await read(function, params);
    return (response[0] as List<dynamic>)
        .cast<List<dynamic>>()
        .map<List<List<String>>>((e) {
      return e.cast<List<dynamic>>().map<List<String>>((e) {
        return e.cast<String>();
      }).toList();
    }).toList();
  }
}
''',
};
