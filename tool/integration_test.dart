import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const _privateKey1 =
    '05decd062bf7f0b8b9026c08624ed4aea1a4f4202f25dec63929c916b6717210';
const _privateKey2 =
    'ea3f9ce401bc7fc73284bf1dd25603bd13f120fea2a66822b760d2d96c68194d';

void main() {
  Process ganacheCli;
  int rpcPort;

  EthPrivateKey first;
  EthPrivateKey second;

  Web3Client client;

  setUpAll(() async {
    rpcPort = await _findUnusedPort();
    print('Starting ganache on port $rpcPort');

    ganacheCli = await Process.start(
      'ganache-cli',
      [
        '--port=$rpcPort',
        '--account=0x$_privateKey1,100000000000000000000',
        '--account=0x$_privateKey2,100000000000000000000',
      ],
    );

    print('Waiting for ganache to start up');
    var connectionAttempts = 0;
    var successful = false;
    do {
      connectionAttempts++;
      try {
        await get('http://127.0.0.1:$rpcPort');
        successful = true;
      } on SocketException {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } while (connectionAttempts < 5);

    if (!successful) {
      throw StateError('ganache did not start up');
    }
  });

  tearDownAll(() => ganacheCli.kill());

  setUp(() {
    first = EthPrivateKey(hexToBytes(_privateKey1));
    second = EthPrivateKey(hexToBytes(_privateKey2));

    client = Web3Client('http://127.0.0.1:$rpcPort', Client());
  });

  tearDown(() => client.dispose());

  test('simple transactions', () async {
    final firstAddress = await first.extractAddress();
    final secondAddress = await second.extractAddress();

    final balanceOfFirst = await client.getBalance(firstAddress);
    final balanceOfSecond = await client.getBalance(secondAddress);
    final value = BigInt.from(1337);

    await client.sendTransaction(
      first,
      Transaction(
        to: secondAddress,
        value: EtherAmount.inWei(value),
        gasPrice: EtherAmount.zero(),
      ),
    );

    expect((await client.getBalance(firstAddress)).getInWei,
        balanceOfFirst.getInWei - value);
    expect((await client.getBalance(secondAddress)).getInWei,
        balanceOfSecond.getInWei + value);
  });
}

Future<int> _findUnusedPort() async {
  // Credits go to https://stackoverflow.com/a/14095888/3260197
  final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  final port = socket.port;
  await socket.close();

  return port;
}
