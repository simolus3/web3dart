import 'dart:typed_data';

Uint8List uint8ListFromList(List<int> data) {
  if (data is Uint8List)
    return data;

  return Uint8List.fromList(data);
}