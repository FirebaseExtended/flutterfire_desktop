part of firebase_storage_dart;

abstract class Source {
  Future<Uint8List> read(int offset, int length);
  int getTotalSize();
}

class BufferSource implements Source {
  final ByteData data;

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

class FileSource implements Source {
  final Future<RandomAccessFile> _raf;
  int _size;

  FileSource(File file, this._size) : _raf = file.open();

  @override
  int getTotalSize() => _size;

  @override
  Future<Uint8List> read(int offset, int length) async {
    final f = await _raf;
    final actualLength = length.clamp(0, _size - offset);

    final buffer = Uint8List(actualLength);

    await f.setPosition(offset);
    await f.readInto(buffer);

    return buffer;
  }
}
