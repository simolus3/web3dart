const testCases = <String, String>{
  r'''
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
]''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
    '[{"inputs":[{"internalType":"uint240","name":"first","type":"uint240"},{"internalType":"uint248","name":"second","type":"uint248"}],"name":"retrieve3","outputs":[{"internalType":"string","name":"","type":"string"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"}]',
    'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<Retrieve3> retrieve3(BigInt first, BigInt second,
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '2783b284'));
    final params = [first, second];
    final response = await read(function, params, atBlock);
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
  r'''
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
]''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
    '[{"inputs":[],"name":"giveMeHello","outputs":[{"internalType":"string","name":"message","type":"string"},{"internalType":"uint256","name":"num1","type":"uint256"},{"internalType":"uint256","name":"num2","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"retrieve","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"num","type":"uint256"}],"name":"store","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
    'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<GiveMeHello> giveMeHello({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '1c1657ea'));
    final params = [];
    final response = await read(function, params, atBlock);
    return GiveMeHello(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> retrieve({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '2e64cec1'));
    final params = [];
    final response = await read(function, params, atBlock);
    return (response[0] as BigInt);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> store(BigInt num,
      {required _i1.Credentials credentials,
      _i1.Transaction? transaction}) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '6057361d'));
    final params = [num];
    return write(credentials, transaction, function, params);
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
  r'''
[
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "",
                "type": "address"
            }
        ],
        "name": "userTotalAmount",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }   
]''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
    '[{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"userTotalAmount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]',
    'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> userTotalAmount(_i1.EthereumAddress $param0,
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '7dbfb5dc'));
    final params = [$param0];
    final response = await read(function, params, atBlock);
    return (response[0] as BigInt);
  }
}
''',
  r'''
[
    {
        "payable": true,
        "stateMutability": "payable",
        "type": "fallback"
    },
    {
        "stateMutability":"payable",
        "type":"receive"
    }
]''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
    '[{"payable":true,"stateMutability":"payable","type":"fallback"},{"stateMutability":"payable","type":"receive"}]',
    'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);
}
''',
  r'''
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
]''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson(
    '[{"inputs":[],"name":"test","outputs":[{"internalType":"string[][6][3]","name":"","type":"string[][6][3]"}],"stateMutability":"view","type":"function"}]',
    'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<List<List<List<String>>>> test({_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, 'f8a8fd6d'));
    final params = [];
    final response = await read(function, params, atBlock);
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
  r'''
{
    "abi": [],
    "devdoc": {
        "kind": "dev",
        "methods": {},
        "version": 1
    }
}''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;

final _contractAbi = _i1.ContractAbi.fromJson('[]', 'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);
}
''',
  r'''
[
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_from",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "_to",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_tokenId",
                "type": "uint256"
            },
            {
                "internalType": "bytes",
                "name": "data",
                "type": "bytes"
            }
        ],
        "name": "safeTransferFrom",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    }
]''': r'''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
import 'package:web3dart/web3dart.dart' as _i1;
import 'dart:typed_data' as _i2;

final _contractAbi = _i1.ContractAbi.fromJson(
    '[{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"payable","type":"function"}]',
    'Contract');

class Contract extends _i1.GeneratedContract {
  Contract(
      {required _i1.EthereumAddress address,
      required _i1.Web3Client client,
      int? chainId})
      : super(_i1.DeployedContract(_contractAbi, address), client, chainId);

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> safeTransferFrom(
      _i1.EthereumAddress _from, _i1.EthereumAddress _to, BigInt _tokenId,
      {required _i1.Credentials credentials,
      _i1.Transaction? transaction}) async {
    final function = self.abi.functions[0];
    assert(checkSignature(function, '42842e0e'));
    final params = [_from, _to, _tokenId];
    return write(credentials, transaction, function, params);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> safeTransferFrom$2(_i1.EthereumAddress _from,
      _i1.EthereumAddress _to, BigInt _tokenId, _i2.Uint8List data,
      {required _i1.Credentials credentials,
      _i1.Transaction? transaction}) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, 'b88d4fde'));
    final params = [_from, _to, _tokenId, data];
    return write(credentials, transaction, function, params);
  }
}
''',
};
