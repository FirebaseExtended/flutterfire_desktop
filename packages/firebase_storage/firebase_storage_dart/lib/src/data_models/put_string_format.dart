/// The format in which a string can be uploaded to the storage bucket via
/// [Reference.putString].
enum PutStringFormat {
  /// A raw string. It will be uploaded as a Base64 string.
  raw,

  /// A Base64 encoded string.
  base64,

  /// A Base64 URL encoded string.
  base64Url,

  /// A data url string.
  dataUrl,
}
