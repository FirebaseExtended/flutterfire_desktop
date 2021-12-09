import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Profile page shows after sign in or registerationg
class ProfilePage extends StatefulWidget {
  // ignore: public_member_api_docs
  const ProfilePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User user;
  String? photoURL;

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser!;
    super.initState();
  }

  /// Map User provider data into a list of Provider Ids.
  List get userProviders => user.providerData.map((e) => e.providerId).toList();

  Future updateProfileImage() async {
    await user.updatePhotoURL(photoURL);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    maxRadius: 60,
                    backgroundImage: NetworkImage(
                      user.photoURL ??
                          'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png',
                    ),
                  ),
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    end: 0,
                    bottom: 0,
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(40),
                      child: InkWell(
                        onTap: () {},
                        radius: 50,
                        child: const SizedBox(
                          width: 35,
                          height: 35,
                          child: Icon(Icons.edit),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(user.displayName ?? 'User'),
              Text(user.email ?? 'User'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (userProviders.contains('password'))
                    const Icon(Icons.mail),
                  if (userProviders.contains('google.com'))
                    SizedBox(
                      width: 24,
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _signOut,
                child: const Text('Update my name'),
              ),
              TextButton(
                onPressed: _signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Example code for sign out.
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}
