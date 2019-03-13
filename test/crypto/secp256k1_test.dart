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

  test('signs message', () {
    // todo https://github.com/web3j/web3j/blob/master/crypto/src/test/java/org/web3j/crypto/SampleKeys.java
  });
}
