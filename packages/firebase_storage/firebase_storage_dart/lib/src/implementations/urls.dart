String makeUrl(String urlPart, String host, String protocol) {
  var origin = host;
  if (protocol == null) {
    origin = 'https://${host}';
  }
  return '${protocol}://${origin}/v0${urlPart}';
}
