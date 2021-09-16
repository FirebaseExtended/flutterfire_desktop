class IPUser {
  IPUser(
    this.idToken,
    this.uid,
    this.email,
    this.refreshToken,
    this.expiresIn,
    this.registered,
  );

  IPUser.fromJson(Map<String, dynamic> json)
      : idToken = json['idToken'],
        uid = json['localId'],
        email = json['email'],
        refreshToken = json['refreshToken'],
        expiresIn = json['expiresIn'],
        registered = json['registered'];

  final String idToken;
  final String uid;
  final String email;
  final String refreshToken;
  final String expiresIn;
  final bool registered;

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        'localId': uid,
        'email': email,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
        'registered': registered,
      };
}
