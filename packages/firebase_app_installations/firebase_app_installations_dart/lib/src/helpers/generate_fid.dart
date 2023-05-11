import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

final fidPattern = RegExp(r'^[cdef][\w-]{21}$');
const invalidFid = '';

/// Generates a new FID using random values.
/// Returns an empty string if FID generation fails for any reason.
String generateFid([Uint8List? byteArray]) {
  try {
    // A valid FID has exactly 22 base64 characters, which is 132 bits, or 16.5
    // bytes. This implementation generates a 17 byte array instead.
    final fidByteArray = byteArray ?? _randBytes(17);

    // Replace the first 4 random bits with the constant FID header of 0b0111.
    fidByteArray[0] = int.parse("01110000", radix: 2) +
        (fidByteArray[0] % int.parse("00010000", radix: 2));

    String fid = _encode(fidByteArray);

    return fidPattern.hasMatch(fid) ? fid : invalidFid;
  } catch (_) {
    // FID generation errored
    return invalidFid;
  }
}

/// Converts a FID Uint8Array to a base64 string representation.
String _encode(Uint8List fidByteArray) {
  String b64String = base64UrlEncode(fidByteArray);

  // Remove the 23rd character that was added because of the extra 4 bits at the
  // end of our 17 byte array, and the '=' padding.
  return b64String.substring(0, 22);
}

Uint8List _randBytes(int n) {
  final Random generator = Random.secure();
  final Uint8List random = Uint8List(n);
  for (int i = 0; i < random.length; i++) {
    random[i] = generator.nextInt(255);
  }
  return random;
}
