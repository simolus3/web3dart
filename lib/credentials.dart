/// Library to create and unlock Ethereum wallets and operate with private keys.
library credentials;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart' as pbkdf2;
import 'package:pointycastle/key_derivators/scrypt.dart' as scrypt;
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/stream/ctr.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:web3dart/src/utils/typed_data.dart';

import 'crypto.dart';
import 'src/crypto/random_bridge.dart';
import 'src/utils/uuid.dart';

part 'src/credentials/address.dart';
part 'src/credentials/credentials.dart';
part 'src/credentials/wallet.dart';
