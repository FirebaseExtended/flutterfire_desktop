part of firebase_storage_dart;

abstract class Source {
  Future<Uint8List> read(int offset, int length);
  int getTotalSize();
}

class BufferSource implements Source {
  final ByteData data;
  int cursor = 0;

  BufferSource(this.data);

  @override
  int getTotalSize() {
    return data.lengthInBytes;
  }

  @override
  Future<Uint8List> read(int offset, int length) async {
    final actualLength = length.clamp(0, data.lengthInBytes - offset);
    return data.buffer.asUint8List(offset, actualLength);
  }
}
