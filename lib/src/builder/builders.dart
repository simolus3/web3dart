import 'package:build/build.dart';
import 'generator.dart';

Builder abiGenerator(BuilderOptions options) => ContractGenerator();

PostProcessBuilder deleteSource(BuilderOptions options) => const FileDeletingBuilder(['.abi.json']);
