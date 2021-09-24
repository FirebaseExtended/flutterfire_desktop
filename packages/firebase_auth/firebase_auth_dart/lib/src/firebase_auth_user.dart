part of firebase_auth_dart;

/// User object wrapping the responses from identity toolkit.
class User {
  /// Default constructor.
  User(
    this.idToken,
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  );

  /// Return a dart user object from Google's identity toolkit response.
  User.fromResponse(Map<String, dynamic> response)
      : idToken = response['idToken'] ?? '',
        email = response['email'],
        uid = response['localId'] ?? '',
        displayName = response['displayName'] ?? '',
        photoUrl = response['photoUrl'] ?? '';

  /// The `idToken` field from API response.
  final String idToken;

  /// The `localId` field from API response.
  final String uid;

  /// The `email` field from API response.
  final String? email;

  /// The `displayName` field from API response.
  final String? displayName;

  /// The `photoUrl` field from API response.
  final String? photoUrl;

  /// A Map representation of this instance.
  Map<String, dynamic> toMap() => {
        'idToken': idToken,
        'localId': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };
}
