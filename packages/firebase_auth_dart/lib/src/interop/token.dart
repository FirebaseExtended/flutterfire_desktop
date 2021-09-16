class IPToken {
  IPToken(
    this.idToken,
    this.refreshToken,
    this.expiresIn,
  );

  IPToken.fromJson(Map<String, dynamic> json)
      : idToken = json['idToken'],
        refreshToken = json['refreshToken'],
        expiresIn = json['expiresIn'];

  final String idToken;

  final String refreshToken;
  final String expiresIn;

  Map<String, dynamic> toJson() => {
        'idToken': idToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
      };
}
