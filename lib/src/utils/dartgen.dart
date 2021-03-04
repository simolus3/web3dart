import 'dart:io';
import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:path/path.dart' as p;

/*

  This application generates dart code to interact with smart contract

  the application receives 3 arguments:
    1: path to abi.json file
    2: contract address
    3: contract name - used to create name of dart File and dart Class

*/


void main(List<String> arguments) async{

  if(arguments.length!=3){
    print('usage: dartgen [abi file] [contract address] [contract name]');
    exit(0);
  }

  final path = p.join(p.current,arguments[0]);
  final abi = File(path);

  await abi.exists().then((exists) {
    if (!exists){
      print('File does not exist');
      exit(0);
    }
  });

  final add = EthereumAddress.fromHex(arguments[1]);
  final contractName = arguments[2];
  final abiBytes = await abi.readAsBytes();
  final abiCode = await abi.readAsString().catchError((e) {
        print(e);
        exit(0);
  });

  //load deployed contract
  final contract = DeployedContract(ContractAbi.fromJson(abiCode, contractName[0].toUpperCase()+contractName.substring(1)), add);
  final functions = contract.functions;
  functions.removeWhere((element) => element.isConstructor);
  final dartCode =
      _getImports() +
      _getClassAndFields(abiBytes, contractName) +
      _getAllFunctions(functions) +
      _getReadFunction() +
      _getWriteFunction() +
      _getEndBracket();

  await File('$contractName.dart').writeAsString(dartCode);
  print('File $contractName.dart successfully created!');

}

String _getImports()=>
    "import 'dart:typed_data';\n"
    "import 'package:web3dart/web3dart.dart';\n"
    "import 'package:meta/meta.dart';\n"
    "import 'package:tuple/tuple.dart';\n\n";

String _getClassAndFields(Uint8List abiBytes, String contractName)=>
    'class ${contractName[0].toUpperCase()+contractName.substring(1)}{\n'
        '  final EthereumAddress contractAddress;\n'
        '  final Web3Client client;\n'
        '  final DeployedContract contract;\n'
        '  final String privateKey;\n'
        '  final int chainId;\n\n'
        '  ${contractName[0].toUpperCase()+contractName.substring(1)}({@required this.contractAddress, @required this.client, @required this.privateKey, this.chainId = 1}):\n'
        "    contract = DeployedContract(ContractAbi.fromJson(String.fromCharCodes(Uint8List.fromList(${abiBytes.toString()})), '${contractName[0].toUpperCase()+contractName.substring(1)}'), contractAddress);\n\n";

String _getParameters(List<FunctionParameter<dynamic>> parameters)=>
  parameters.map((e) => '${_solTypeToDart(e.type.name)} ${e.name}').toList().toString();


String _getReturnType(ContractFunction function, String outputs) {
  return function.outputs.length>1?'Tuple${function.outputs.length}<${outputs.substring(1,outputs.length-1)}>':
    '${_solTypeToDart(function.outputs[0].type.name)}';
}


String _getResultStatement(ContractFunction function) {
  final outputs = _getOutputs(function);
  return '    final result = Tuple${function.outputs
      .length}<${outputs.substring(1,outputs.length-1)}>.fromList(res);\n';
}

String _getOutputs(ContractFunction function) => function.outputs.map((e) => _solTypeToDart(e.type.name)).toList().toString();

String _getAllFunctions(List<ContractFunction> functions){
  var allFunctions='';
  functions.forEach((function) {
    allFunctions += _getFunction(function);
  });
  return allFunctions;
}

String _getFunction(ContractFunction function){
  final parameters = _getParameters(function.parameters);
  final paramList  = function.parameters.map((e) => e.name).toList();

  if(function.isConstant) {
    final outputs = _getOutputs(function);
    final returnType = _getReturnType(function, outputs);
    return '  Future<$returnType> ${function.name}(${parameters.substring(1, parameters.length-1)}) async {\n'
        "    final function = contract.function('${function.name}');\n"
        '    final params = $paramList;\n'
        '    final res = await _readFunction(contract, function, params);\n'
        '${(function.outputs.length>1?_getResultStatement(function):null)}'
        '    return result${function.outputs.length==1?' as ${outputs}':''};\n'
        '  }\n\n';


  } else{
    return
      '  Future<String> ${function.name}(${parameters.substring(1, parameters.length-1)}) async {\n'
      "    final function = contract.function('${function.name}');\n"
      '    final params = $paramList;\n'
          '    final credentials = await client.credentialsFromPrivateKey(privateKey);\n'
          '    final transaction = Transaction.callContract(contract: contract, function: function, parameters: params);\n'
          '    return await _writeFunction(credentials, transaction);\n'
          '  }\n\n';


  }
}


String _getReadFunction()=>
    '  Future<List<dynamic>> _readFunction(DeployedContract contract, ContractFunction function, List<dynamic> params) async {\n'
    '    return await client.call(contract: contract, function: function, params: params);\n'
    '  }\n\n';


String _getWriteFunction()=>
    '  Future<String> _writeFunction(Credentials credentials, Transaction transaction) async {\n'
    '    return await client.sendTransaction(credentials, transaction, chainId: chainId);\n'
    '  }\n\n';

String _getEndBracket()=>'}\n';

String _solTypeToDart(String paramType){
  switch(paramType){
    case 'uint256': return 'BigInt'; break;
    case 'string': return 'String'; break;
    case 'address': return 'EthereumAddress'; break;
    default:return paramType;
  }

}