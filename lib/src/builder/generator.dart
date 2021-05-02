import 'dart:async';
import 'dart:convert';

import 'package:code_builder/code_builder.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart';
import 'package:web3dart/contracts.dart';

import 'utils.dart';

class ContractGenerator implements Builder {
  const ContractGenerator();

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.abi.json': ['.g.dart']
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final withoutExtension =
        inputId.path.substring(0, inputId.path.length - '.abi.json'.length);

    var abiCode = await buildStep.readAsString(inputId);
    // Remove unnecessary whitespace
    abiCode = json.encode(json.decode(abiCode));
    final abi = ContractAbi.fromJson(abiCode, _suggestName(withoutExtension));

    final outputId = AssetId(inputId.package, '$withoutExtension.g.dart');
    await buildStep.writeAsString(outputId, _generateForAbi(abi, abiCode));
  }

  String _suggestName(String pathWithoutExtension) {
    final base = basename(pathWithoutExtension);
    return base[0].toUpperCase() + base.substring(1);
  }

  //main method that parses abi to dart code
  String _generateForAbi(ContractAbi abi, String abiCode) {
    final library = Library((b) {
      b.body.addAll([
        Class((b) => b
          ..name = abi.name
          ..extend = generatedContract
          ..methods.addAll(_getMethods(abi.functions))
          ..constructors.add(Constructor(
            (b) => b
              ..optionalParameters.addAll(_constructorParams)
              ..initializers.add(callSuper([
                deployedContract.newInstance([
                  contractAbi.newInstanceNamed(
                    'fromJson',
                    [literalString(abiCode), literalString(abi.name)],
                  ),
                ]),
                refer('client'),
                refer('chainId'),
              ]).code),
          )))
      ]);
      b.body.addAll(_customClasses(abi.functions));
    });

    final emitter = DartEmitter(
        allocator: Allocator.simplePrefixing(), useNullSafetySyntax: true);
    return DartFormatter().format('''
// Generated code, do not modify. Run `build_runner build` to re-generate!
// @dart=2.12
${library.accept(emitter)}
''');
  }

  // Create custom classes to encapsulate responses for functions that return
  // multiple values
  List<Class> _customClasses(List<ContractFunction> functions) {
    functions = [
      for (final fun in functions)
        if (fun.outputs.length > 1) fun,
    ];

    final customClasses = <Class>[];
    for (final function in functions) {
      final params = <Parameter>[];
      final fields = <Field>[];
      final initializers = <Code>[];
      for (var i = 0; i < function.outputs.length; i++) {
        final name = function.outputs[i].name.isEmpty
            ? 'var${i + 1}'
            : function.outputs[i].name;
        final type = function.outputs[i].type.toDart();

        params.add(Parameter((b) => b
          ..name = name
          // ..type = type
          ..toThis = true));

        fields.add(Field((b) => b
          ..name = name
          ..type = type
          ..modifier = FieldModifier.final$));

        initializers
            .add(refer(name).assign(refer('response[$i]').asA(type)).code);
      }

      customClasses.add(Class((b) => b
        ..name = _customClassName(function.name)
        ..fields.addAll(fields)
        ..constructors.add(Constructor((b) => b
          ..requiredParameters.add(Parameter((b) => b
            ..name = 'response'
            ..type = listify(dynamicType)))
          ..initializers.addAll(initializers)))));
    }

    return customClasses;
  }

  List<Method> _getMethods(List<ContractFunction> functions) {
    final methods = <Method>[];
    functions.removeWhere((element) => element.isConstructor);
    for (final function in functions) {
      methods.add(Method((b) {
        b
          ..modifier = MethodModifier.async
          ..returns = _returnType(function)
          ..name = function.name
          ..body = function.isConstant
              ? _bodyForImmutable(function)
              : _bodyForMutable(function)
          ..requiredParameters.addAll(_getParameters(function));

        if (!function.isConstant) {
          b.optionalParameters.add(Parameter((b) => b
            ..type = credentials
            ..name = 'credentials'
            ..named = true
            ..required = true));
        }
      }));
    }

    return methods;
  }

  List<Parameter> _getParameters(ContractFunction function) {
    final parameters = <Parameter>[];
    for (final param in function.parameters) {
      parameters.add(Parameter((b) => b
        ..name = param.name
        ..type = param.type.toDart()));
    }

    return parameters;
  }

  Code _bodyForImmutable(ContractFunction function) {
    final params = function.parameters.map((e) => e.name).toList();

    final outputs = function.outputs;
    Expression returnValue;
    if (outputs.length > 1) {
      returnValue =
          refer(_customClassName(function.name)).call([refer('response')]);
    } else {
      returnValue = refer('response')
          .index(literalNum(0))
          .asA(function.outputs.single.type.toDart());
    }

    return Block((b) => b
      ..addExpression(
          CodeExpression(funFunction.call([literalString(function.name)]).code)
              .assignFinal('function'))
      ..addExpression(literalList(params).assignFinal('params'))
      ..addExpression(refer('read')
          .call([argContract, argFunction, argParams])
          .awaited
          .assignFinal('response'))
      ..addExpression(returnValue.returned));
  }

  Code _bodyForMutable(ContractFunction function) {
    final params = function.parameters.map((e) => e.name).toList();

    return Block((b) => b
      ..addExpression(funFunction
          .call([literalString(function.name)]).assignFinal('function'))
      ..addExpression(literalList(params).assignFinal('params'))
      ..addExpression(funCallContract.call(
        const [],
        {
          'contract': refer('self'),
          'function': refer('function'),
          'parameters': refer('params'),
        },
      ).assignFinal('transaction'))
      ..addExpression(funWrite));
  }
}

Reference _returnType(ContractFunction function) {
  if (!function.isConstant) {
    return futurize(string);
  } else if (function.outputs.isEmpty) {
    return futurize(refer('void'));
  } else if (function.outputs.length > 1) {
    return futurize(refer(_customClassName(function.name)));
  } else {
    return futurize(function.outputs[0].type.toDart());
  }
}

final _constructorParams = [
  Parameter((b) => b
    ..name = 'address'
    ..type = ethereumAddress
    ..named = true
    ..required = true),
  Parameter((b) => b
    ..name = 'client'
    ..named = true
    ..required = true),
  Parameter((b) => b
    ..name = 'chainId'
    ..type = dartInt.rebuild((b) => b.isNullable = true)
    ..required = false
    ..named = true)
];

String _customClassName(String functionName) =>
    '${functionName[0].toUpperCase()}${functionName.substring(1)}';
