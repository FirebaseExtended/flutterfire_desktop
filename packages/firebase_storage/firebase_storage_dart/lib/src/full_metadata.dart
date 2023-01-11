part of firebase_storage_dart;

class FullMetadata {
  FullMetadata._(this._metadata);

  final Map<String, dynamic> _metadata;

  String? get bucket {
    return _metadata['bucket'];
  }

  String? get cacheControl {
    return _metadata['cacheControl'];
  }

  String? get contentDisposition {
    return _metadata['contentDisposition'];
  }

  String? get contentEncoding {
    return _metadata['contentEncoding'];
  }

  String? get contentLanguage {
    return _metadata['contentLanguage'];
  }

  String? get contentType {
    return _metadata['contentType'];
  }

  Map<String, String>? get customMetadata {
    return _metadata['customMetadata'] == null
        ? null
        : Map<String, String>.from(_metadata['customMetadata']);
  }

  String get fullPath {
    return _metadata['fullPath'];
  }

  String? get generation {
    return _metadata['generation'];
  }

  String? get metadataGeneration {
    return _metadata['metadataGeneration'];
  }

  String? get md5Hash {
    return _metadata['md5Hash'];
  }

  String? get metageneration {
    return _metadata['metageneration'];
  }

  String get name {
    return _metadata['name'];
  }

  int? get size {
    return _metadata['size'];
  }

  DateTime? get timeCreated {
    return _metadata['creationTimeMillis'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(_metadata['creationTimeMillis']);
  }

  DateTime? get updated {
    return _metadata['updatedTimeMillis'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(_metadata['updatedTimeMillis']);
  }
}
