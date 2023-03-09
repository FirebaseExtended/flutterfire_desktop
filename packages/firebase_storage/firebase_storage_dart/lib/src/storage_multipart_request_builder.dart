part of firebase_storage_dart;

class Part {
  final String contentType;
  final List<int> bytes;

  Part(this.contentType, this.bytes);
}

final _r = Random.secure();

class MultipartContent {
  final String boundary;
  final Uint8List _bytes;

  MultipartContent._(this._bytes, this.boundary);

  factory MultipartContent.fromParts(List<Part> parts) {
    final boundary = List.generate(32, (index) => _r.nextInt(10)).join('');
    final builder = BytesBuilder();

    for (final part in parts) {
      builder.add(utf8.encode('--'));
      builder.add(utf8.encode(boundary));
      builder.add(utf8.encode('\r\n'));
      builder.add(
        utf8.encode('Content-Type: ${part.contentType}\r\n\r\n'),
      );
      builder.add(part.bytes);
      builder.add(utf8.encode('\r\n'));
    }

    builder.add(utf8.encode('--'));
    builder.add(utf8.encode(boundary));

    return MultipartContent._(builder.toBytes(), boundary);
  }

  List<int> getBodyBytes() {
    return _bytes;
  }
}

class MultipartBuilder {
  final List<Part> parts = [];

  void add(String contentType, List<int> bytes) {
    parts.add(Part(contentType, bytes));
  }

  MultipartContent buildContent() {
    return MultipartContent.fromParts(parts);
  }
}
