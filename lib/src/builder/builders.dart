import 'package:build/build.dart';

import 'generator.dart';

Builder abiGenerator(BuilderOptions options) {
  return const ContractGenerator();
}

PostProcessBuilder deleteSource(BuilderOptions options) {
  return const FileDeletingBuilder(['.abi.json']);
}
