import 'package:test_api/test_api.dart';
import 'package:web3dart/crypto.dart';

const Map<String, String> _privateKeysToAddress = {
  'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e':
      '76778e046D73a5B8ce3d03749cE6B1b3D6a12E36',
  'f1f7a560cf6a730df8404eca67e28c1d61a611634417aaa45aa3e2bec84dd71b':
      'C914Bb2ba888e3367bcecEb5C2d99DF7C7423706',
  '07a0eeacaf4eb0a43a75c4da0c22c22ab1b4bcc29cac198432b93fa71ec62b39':
      'ea7624696aA08Cec594e292eC16dcFC5dA9bDa1f',
};

void main() {
  _privateKeysToAddress.forEach((key, address) {
    test('finds correct address for private key', () {
      final publicKey = privateKeyBytesToPublic(hexToBytes(key));
      final foundAddress = publicKeyToAddress(publicKey);

      expect(bytesToHex(foundAddress), equalsIgnoringCase(address));
    });
  });

  test('finds public key for private key', () {
    expect(
        bytesToHex(privateKeyBytesToPublic(hexToBytes(
            'a392604efc2fad9c0b3da43b5f698a2e3f270f170d859912be0d54742275c5f6'))),
        '506bc1dc099358e5137292f4efdd57e400f29ba5132aa5d12b18dac1c1f6aab'
        'a645c0b7b58158babbfa6c6cd5a48aa7340a8749176b120e8516216787a13dc76');
  });

  test('produces a valid signature', () {
    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/test/index.js#L523
    final hashedPayload = hexToBytes('82ff40c0a986c6a5cfad4ddf4c3aa6996f1a7837f9c398e17e5de5cbd5a12b28');
    final privKey = hexToBytes('3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1');
    final sig = sign(hashedPayload, privKey);

    expect(sig.r, hexToInt('99e71a99cb2270b8cac5254f9e99b6210c6c10224a1579cf389ef88b20a1abe9'));
    expect(sig.s, hexToInt('129ff05af364204442bdb53ab6f18a99ab48acc9326fa689f228040429e3ca66'));
    expect(sig.v, 27);
  });
}
