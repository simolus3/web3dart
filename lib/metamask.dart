/// Metamask wrapper using JS interop.
///
/// You should only import `package:web3dart/metamask.dart` on web projects. Use
/// conditional imports if necessary.
@experimental
library metamask;

import 'dart:async';
import 'dart:js';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

part 'src/metamask/metamask.dart';
