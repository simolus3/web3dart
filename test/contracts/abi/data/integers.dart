// Note: Our parser will pick up the D suffix as a BigInt (radix 10) and H as a
// hex BigInt
const content = r'''
{
  "uInts": {
    "args": [
      0,
      "7fffffffffffffffH",
      "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffH"
    ],
    "result": "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "types": ["uint256", "uint256", "uint256"]
  },
  "ints": {
    "args": [
      0,
      "9223372036854775807D",
      "-9223372036854775808D",
      -1
    ],
    "result": "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "types": ["int256", "int256", "int256", "int256"]
  },
  "booleans": {
    "args": [
      false,
      true
    ],
    "result": "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001",
    "types": ["bool", "bool"]
  }
}
''';
