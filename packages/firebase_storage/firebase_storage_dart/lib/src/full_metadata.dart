part of firebase_storage_dart;

class FullMetadata {
  final String? bucket;
  final String? cacheControl;
  final String? contentDisposition;
  final String? contentEncoding;
  final String? contentLanguage;
  final String? contentType;
  final Map<String, String>? customMetadata;
  final String fullPath;
  final String? generation;
  final String? metadataGeneration;
  final String? md5Hash;
  final String? metageneration;
  final String name;
  final int? size;
  final DateTime? timeCreated;
  final DateTime? updated;

  FullMetadata._({
    required this.fullPath,
    required this.name,
    this.bucket,
    this.cacheControl,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    this.customMetadata,
    this.generation,
    this.metadataGeneration,
    this.md5Hash,
    this.metageneration,
    this.size,
    this.timeCreated,
    this.updated,
  });

  factory FullMetadata._fromObject(String fullPath, gapi.Object object) {
    return FullMetadata._(
      fullPath: fullPath,
      name: object.name!,
      bucket: object.bucket,
      cacheControl: object.cacheControl,
      contentDisposition: object.contentDisposition,
      contentEncoding: object.contentEncoding,
      contentLanguage: object.contentLanguage,
      contentType: object.contentType,
      customMetadata: object.metadata,
      generation: object.generation,
      md5Hash: object.md5Hash,
      metadataGeneration: object.metageneration,
      metageneration: object.metageneration,
      size: int.tryParse(object.size ?? ''),
      timeCreated: object.timeCreated,
      updated: object.updated,
    );
  }
}
