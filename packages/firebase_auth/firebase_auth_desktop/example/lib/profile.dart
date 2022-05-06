import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth.dart';
import 'auth_service.dart';
import 'sms_dialog.dart';

/// Displayed as a profile image if the user doesn't have one.
const placeholderImage =
    'https://upload.wikimedia.org/wikipedia/commons/c/cd/Portrait_Placeholder_Square.png';

/// Profile page shows after sign in or registerationg
class ProfilePage extends StatefulWidget {
  // ignore: public_member_api_docs
  const ProfilePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();

  late User user;
  late TextEditingController controller;

  String? photoURL;

  bool showSaveButton = false;
  bool isLoading = false;

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser!;
    controller = TextEditingController(text: user.displayName);

    controller.addListener(_onNameChanged);

    FirebaseAuth.instance.userChanges().listen((event) {
      if (event != null && mounted) {
        setState(() {
          user = event;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    controller.removeListener(_onNameChanged);
    super.dispose();
  }

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  void _onNameChanged() {
    setState(() {
      if (controller.text == user.displayName || controller.text.isEmpty) {
        showSaveButton = false;
      } else {
        showSaveButton = true;
      }
    });
  }

  /// Map User provider data into a list of Provider Ids.
  List get userProviders => user.providerData.map((e) => e.providerId).toList();

  Future updateDisplayName() async {
    await user.updateDisplayName(controller.text);

    setState(() {
      showSaveButton = false;
    });

    // ignore: use_build_context_synchronously
    ScaffoldSnackbar.of(context).show('Name updated');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        body: Stack(
          children: [
            Center(
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
                            user.photoURL ?? placeholderImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      textAlign: TextAlign.center,
                      controller: controller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        alignLabelWithHint: true,
                        label: Center(
                          child: Text(
                            'Click to add a display name',
                          ),
                        ),
                      ),
                    ),
                    Text(user.email ?? user.phoneNumber ?? 'User'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (userProviders.contains('phone'))
                          const Icon(Icons.phone),
                        if (userProviders.contains('password'))
                          const Icon(Icons.mail),
                        if (userProviders.contains('google.com'))
                          SizedBox(
                            width: 24,
                            child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png',
                            ),
                          ),
                        if (userProviders.contains('github.com'))
                          SizedBox(
                            width: 24,
                            child: Image.asset('assets/github.png'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    if (!userProviders.contains('phone'))
                      TextButton(
                        onPressed: _linkWithPhone,
                        child: const Text('Link with phone number'),
                      ),
                    if (!userProviders.contains('google.com'))
                      TextButton(
                        onPressed: _linkWithOAuth,
                        child: const Text('Link with Google'),
                      ),
                    const SizedBox(height: 40),
                    if (userProviders.contains('phone'))
                      TextButton(
                        onPressed: _updatePhoneNumber,
                        child: const Text('Update my phone'),
                      ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _signOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              end: 40,
              top: 40,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: !showSaveButton
                    ? SizedBox(key: UniqueKey())
                    : TextButton(
                        onPressed: isLoading ? null : updateDisplayName,
                        child: const Text('Save changes'),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _linkWithOAuth() async {
    try {
      await authService.linkWithGoogle();
    } on FirebaseAuthException catch (e) {
      ScaffoldSnackbar.of(context).show('${e.message}');
      log('$e');
    } finally {
      setIsLoading();
    }
  }

  Future<void> _linkWithPhone() async {
    try {
      final phoneNumber =
          await ExampleDialog.of(context).show('Phone number:', 'Link');

      if (phoneNumber != null) {
        final confirmationResult = await user.linkWithPhoneNumber(phoneNumber);

        final smsCode =
            // ignore: use_build_context_synchronously
            await ExampleDialog.of(context).show('SMS Code:', 'Sign in');

        if (smsCode != null) {
          await confirmationResult.confirm(smsCode);
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldSnackbar.of(context).show('${e.message}');
      log('$e');
    } finally {
      setIsLoading();
    }
  }

  Future<void> _updatePhoneNumber() async {
    try {
      final phoneNumber =
          await ExampleDialog.of(context).show('Phone number:', 'Get SMS');

      if (phoneNumber != null) {
        final res =
            await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);

        // ignore: use_build_context_synchronously
        final smsCode =
            // ignore: use_build_context_synchronously
            await ExampleDialog.of(context).show('SMS Code:', 'Sign in');

        if (smsCode != null) {
          await user.updatePhoneNumber(
            PhoneAuthProvider.credential(
              verificationId: res.verificationId,
              smsCode: smsCode,
            ),
          );

          log('${user.phoneNumber}');
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldSnackbar.of(context).show('${e.message}');
      log('$e');
    } finally {
      setIsLoading();
    }
  }

  Future<void> _signOut() async {
    await authService.signOut();
  }
}
