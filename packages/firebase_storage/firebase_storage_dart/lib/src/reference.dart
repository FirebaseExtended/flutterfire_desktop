part of firebase_storage_dart;

class Reference {
  Reference.fromPath({required this.storage, required String path})
      : location = Location(path, storage.bucket);
  Reference._(this.storage, this.location);

  /// The storage service associated with this reference.
  final FirebaseStorage storage;

  ///An fbs.location, or the URL at
  ///     which to base this object, in one of the following forms:
  ///         gs://<bucket>/<object-path>
  ///         http[s]://firebasestorage.googleapis.com/
  ///                     <api-version>/b/<bucket>/o/<object-path>
  ///     Any query or fragment strings will be ignored in the http[s]
  ///     format. If no value is passed, the storage object will use a URL based on
  ///     the project ID of the base firebase.App instance.
  ///
  final Location location;

  /// The name of the bucket containing this reference's object.
  String get bucket => location.bucket;

  /// The full path of this object.
  String get fullPath => location.path;

  /// The short name of this object, which is the last component of the full path.
  ///
  /// For example, if fullPath is 'full/path/image.png', name is 'image.png'.
  String get name => paths.lastComponent(location.path);

  /// A reference pointing to the parent location of this reference, or `null`
  /// if this reference is the root.
  Reference? get parent {
    final newPath = paths.parent(this.location.path);
    if (newPath == null) {
      return null;
    }
    final newLocation = Location(
      newPath,
      location.bucket,
    );
    return Reference._(storage, newLocation);
  }

  /// A reference to the root of this reference's bucket.
  Reference get root {
    final newLocation = Location(
      '',
      location.bucket,
    );
    return Reference._(storage, newLocation);
  }

  /// Returns a reference to a relative path from this reference.
  ///
  /// [path] The relative path from this reference. Leading, trailing, and
  ///   consecutive slashes are removed.
  Reference child(String path) {
    final newPath = paths.child(location.path, path);
    final newLocation = Location(
      newPath,
      location.bucket,
    );
    return Reference._(storage, newLocation);
  }

  /// Deletes the object at this reference's location.
  Future<void> delete() {
    throw UnimplementedError();
    //   final urlPart = location.fullServerUrl();
    // final url = makeUrl(urlPart, service.host, service._protocol);
    // const method = 'DELETE';
    // final timeout = storage.maxOperationRetryTime;

    // void handler(Connection<String> _xhr,String _text) {}
    // final requestInfo =  RequestInfo(url, method, handler, timeout);
    // requestInfo.successCodes = [200, 204];
    // requestInfo.errorHandler = objectErrorHandler(location);
    // return requestInfo;
  }

  /// Fetches a long lived download URL for this object.
  Future<String> getDownloadURL() async {
    // ref._throwIfRoot('getDownloadURL');
    try {
      return await storage._api.refernceApi.getDownloadURL(reference: this);
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches metadata for the object at this location, if one exists.
  Future<FullMetadata> getMetadata() async {
    try {
      return await storage._api.refernceApi.getMetaData(
        reference: this,
      );
    } catch (_) {
      rethrow;
    }
  }

  /// List items (files) and prefixes (folders) under this storage reference.
  ///
  /// List API is only available for Firebase Rules Version 2.
  ///
  /// GCS is a key-blob store. Firebase Storage imposes the semantic of '/'
  /// delimited folder structure. Refer to GCS's List API if you want to learn more.
  ///
  /// To adhere to Firebase Rules's Semantics, Firebase Storage does not support
  /// objects whose paths end with "/" or contain two consecutive "/"s. Firebase
  /// Storage List API will filter these unsupported objects. [list] may fail
  /// if there are too many unsupported objects in the bucket.
  Future<ListResult> list([ListOptions? options]) async {
    assert(options == null ||
        options.maxResults == null ||
        options.maxResults! > 0 && options.maxResults! <= 1000);
    try {
      return await storage._api.refernceApi
          .getRefListData(reference: this, options: options);
    } catch (_) {
      rethrow;
    }
  }

  /// List all items (files) and prefixes (folders) under this storage reference.
  ///
  /// This is a helper method for calling [list] repeatedly until there are no
  /// more results. The default pagination size is 1000.
  ///
  /// Note: The results may not be consistent if objects are changed while this
  /// operation is running.
  ///
  /// Warning: [listAll] may potentially consume too many resources if there are
  /// too many results.
  Future<ListResult> listAll() async {
    ListResult result = await list();
    List<String> _items = result._items.toList();
    List<String> _prefixes = result._prefixes.toList();
    while (result.nextPageToken != null) {
      result = await list(ListOptions(pageToken: result.nextPageToken));
      _items.addAll(result._items);
      _prefixes.addAll(result._prefixes);
    }
    return ListResult(storage, null, _items, _prefixes);
  }

  /// Asynchronously downloads the object at the StorageReference to a list in memory.
  ///
  /// Returns a [Uint8List] of the data.
  ///
  /// If the [maxSize] (in bytes) is exceeded, the operation will be canceled. By
  /// default the [maxSize] is 10mb (10485760 bytes).
  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    assert(maxSize > 0);
    try {
      return await storage._api.refernceApi
          .getData(reference: this, maxSize: maxSize);
    } catch (_) {
      rethrow;
    }
  }

  /// Uploads data to this reference's location.
  ///
  /// Use this method to upload fixed sized data as a [Uint8List].
  ///
  /// Optionally, you can also set metadata onto the uploaded object.
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    try {
      return storage._api.refernceApi
          .putData(reference: this, data: data, metadata: metadata);
    } catch (_) {
      rethrow;
    }
  }

  /// Upload a [Blob]. Note; this is only supported on web platforms.
  ///
  /// Optionally, you can also set metadata onto the uploaded object.
  UploadTask putBlob(dynamic blob, [SettableMetadata? metadata]) {
    assert(blob != null);
    try {
      return storage._api.refernceApi
          .putBlob(reference: this, blob: blob, metadata: metadata);
    } catch (_) {
      rethrow;
    }
  }

  /// Upload a [File] from the filesystem. The file must exist.
  ///
  /// Optionally, you can also set metadata onto the uploaded object.
  UploadTask putFile(File file, [SettableMetadata? metadata]) {
    assert(file.absolute.existsSync());
    try {
      return storage._api.refernceApi
          .putFile(reference: this, file: file, metadata: metadata);
    } catch (_) {
      rethrow;
    }
  }

  /// Upload a [String] value as a storage object.
  ///
  /// Use [PutStringFormat] to correctly encode the string:
  ///   - [PutStringFormat.raw] the string will be encoded in a Base64 format.
  ///   - [PutStringFormat.dataUrl] the string must be in a data url format
  ///     (e.g. "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="). If no
  ///     [SettableMetadata.mimeType] is provided as part of the [metadata]
  ///     argument, the [mimeType] will be automatically set.
  ///   - [PutStringFormat.base64] will be encoded as a Base64 string.
  ///   - [PutStringFormat.base64Url] will be encoded as a Base64 string safe URL.
  UploadTask putString(
    String data, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata? metadata,
  }) {
    String _data = data;
    PutStringFormat _format = format;
    SettableMetadata? _metadata = metadata;

    // Convert any raw string values into a Base64 format
    if (format == PutStringFormat.raw) {
      _data = base64.encode(utf8.encode(_data));
      _format = PutStringFormat.base64;
    }

    // Convert a data_url into a Base64 format
    if (format == PutStringFormat.dataUrl) {
      _format = PutStringFormat.base64;
      UriData uri = UriData.fromUri(Uri.parse(data));
      assert(uri.isBase64);
      _data = uri.contentText;

      if (_metadata == null && uri.mimeType.isNotEmpty) {
        _metadata = SettableMetadata(
          contentType: uri.mimeType,
        );
      }

      // If the data_url contains a mime-type & the user has not provided it,
      // set it
      if ((_metadata!.contentType == null || _metadata.contentType!.isEmpty) &&
          uri.mimeType.isNotEmpty) {
        _metadata = SettableMetadata(
          cacheControl: metadata!.cacheControl,
          contentDisposition: metadata.contentDisposition,
          contentEncoding: metadata.contentEncoding,
          contentLanguage: metadata.contentLanguage,
          contentType: uri.mimeType,
        );
      }
    }

    try {
      return storage._api.refernceApi.putString(
          reference: this, data: _data, format: _format, metadata: metadata);
    } catch (_) {
      rethrow;
    }
  }

  /// Updates the metadata on a storage object.
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) {
    try {
      return storage._api.refernceApi
          .updateMetadata(reference: this, metadata: metadata);
    } catch (_) {
      rethrow;
    }
  }

  /// Writes a remote storage object to the local filesystem.
  ///
  /// If a file already exists at the given location, it will be overwritten.
  DownloadTask writeToFile(File file) {
    try {
      return storage._api.refernceApi.writeToFile(reference: this, file: file);
    } catch (_) {
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Reference &&
      other.fullPath == fullPath &&
      other.storage == storage;

  @override
  String toString() =>
      '$Reference(app: ${storage.app.name}, fullPath: $fullPath)';

  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
}
