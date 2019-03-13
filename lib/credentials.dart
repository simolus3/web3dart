/// Library to create and unlock Ethereum wallets,
library credentials;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:web3dart/src/utils/typed_data.dart';

import 'crypto.dart';

part 'src/credentials/address.dart';
part 'src/credentials/credentials.dart';