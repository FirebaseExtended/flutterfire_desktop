import 'token.dart';

class IPUser {
  IPUser(
    this.token,
    this.uid,
    this.email,
  );

  IPUser.fromJson(Map<String, dynamic> json)
      : token = IPToken.fromJson(json),
        uid = json['localId'],
        email = json['email'];

  final IPToken token;
  final String uid;
  final String email;

  Map<String, dynamic> toJson() => {
        ...token.toJson(),
        'localId': uid,
        'email': email,
      };
}
