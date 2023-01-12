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

  factory FullMetadata._fromJson(Map<String, dynamic> json) {
    return FullMetadata._(
      fullPath: json['fullPath'] as String,
      name: json['name'] as String,
      bucket: json['bucket'] as String?,
      cacheControl: json['cacheControl'] as String?,
      contentDisposition: json['contentDisposition'] as String?,
      contentEncoding: json['contentEncoding'] as String?,
      contentLanguage: json['contentLanguage'] as String?,
      contentType: json['contentType'] as String?,
      customMetadata: json['customMetadata'] as Map<String, String>,
      generation: json['generation'] as String?,
      md5Hash: json['md5Hash'] as String?,
      metageneration: json['metageneration'] as String?,
      metadataGeneration: json['metageneration'] as String?,
      size: json['size'] as int?,
      timeCreated: json['timeCreated'] == null
          ? null
          : DateTime.parse(json['timeCreated'] as String),
      updated: json['updated'] == null
          ? null
          : DateTime.parse(json['timeCreated'] as String),
    );
  }
}
