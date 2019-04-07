import 'dart:convert';
import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart';

class LengthTrackingByteSink extends ByteConversionSinkBase {
  final Uint8Buffer _buffer = Uint8Buffer();
  int _length = 0;

  int get length => _length;

  Uint8List asBytes() {
    return _buffer.buffer.asUint8List(0, _length);
  }

  @override
  void add(List<int> chunk) {
    _buffer.addAll(chunk);
    _length += chunk.length;
  }

  void addByte(int byte) {
    _buffer.add(byte);
    _length++;
  }

  void setRange(int start, int end, List<int> content) {
    _buffer.setRange(start, end, content);
  }

  @override
  void close() {
    // no-op, never used
  }
}
