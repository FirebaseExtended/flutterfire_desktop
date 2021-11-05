// ignore_for_file: public_member_api_docs, use_build_context_synchronously, avoid_print

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Helper class to show a snackbar using the passed context.
class ScaffoldSnackbar {
  ScaffoldSnackbar(this._context);

  /// The scaffold of current context.
  factory ScaffoldSnackbar.of(BuildContext context) {
    return ScaffoldSnackbar(context);
  }

  final BuildContext _context;

  /// Helper method to show a SnackBar.
  void show(String message) {
    ScaffoldMessenger.of(_context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}

/// Entrypoint example for various sign-in flows with Firebase.
class SignInPage extends StatefulWidget {
  SignInPage({Key? key}) : super(key: key);

  /// The page title.
  final String title = 'Sign In & Out';

  @override
  State<StatefulWidget> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  User? user;

  @override
  void initState() {
    _auth.userChanges().listen(
          (event) => setState(() => user = event),
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () async {
                  final user = _auth.currentUser;
                  if (user == null) {
                    ScaffoldSnackbar.of(context).show('No one has signed in.');
                    return;
                  }
                  await _signOut();

                  final uid = user.uid;
                  ScaffoldSnackbar.of(context)
                      .show('$uid has successfully signed out.');
                },
                child: const Text('Sign out'),
              );
            },
          )
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return ListView(
            padding: const EdgeInsets.all(8),
            children: <Widget>[
              _UserInfoCard(user: user),
              const _EmailPasswordForm(),
              const _EmailLinkSignInSection(),
              const _AnonymouslySignInSection(),
              const _PhoneSignInSection(),
              const _OtherProvidersSignInSection(),
            ],
          );
        },
      ),
    );
  }

  /// Example code for sign out.
  Future<void> _signOut() async {
    await _auth.signOut();
  }
}

class _UserInfoCard extends StatefulWidget {
  const _UserInfoCard({Key? key, this.user}) : super(key: key);

  final User? user;

  @override
  _UserInfoCardState createState() => _UserInfoCardState();
}

class _UserInfoCardState extends State<_UserInfoCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.center,
              child: const Text(
                'User info',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.user != null)
              if (widget.user!.photoURL != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    width: 200,
                    child: Image.network(widget.user!.photoURL!),
                  ),
                )
              else
                Align(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.black,
                    child: const Text(
                      'No image',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            Text(
              widget.user == null
                  ? 'Not signed in'
                  : '${widget.user!.isAnonymous ? 'User is anonymous\n\n' : ''}'
                      'Email: ${widget.user!.email} (verified: ${widget.user!.emailVerified})\n\n'
                      'Phone number: ${widget.user!.phoneNumber}\n\n'
                      'Name: ${widget.user!.displayName}\n\n\n'
                      'ID: ${widget.user!.uid}\n\n'
                      //'Tenant ID: ${widget.user!.tenantId}\n\n'
                      'Refresh token: ${widget.user!.refreshToken}\n\n\n'
              //'Created: ${widget.user!.metadata.creationTime.toString()}\n\n'
              //'Last login: ${widget.user!.metadata.lastSignInTime}\n\n',
              ,
            ),
            // if (widget.user != null)
            //   Column(
            //     crossAxisAlignment: CrossAxisAlignment.stretch,
            //     children: [
            //       Text(
            //         widget.user!.providerData.isEmpty
            //             ? 'No providers'
            //             : 'Providers:',
            //         style: const TextStyle(fontWeight: FontWeight.bold),
            //         textAlign: TextAlign.center,
            //       ),
            //       for (var provider in widget.user!.providerData)
            //         Dismissible(
            //           key: Key(provider.uid!),
            //           onDismissed: (action) =>
            //               widget.user!.unlink(provider.providerId),
            //           child: Card(
            //             color: Colors.grey[700],
            //             child: ListTile(
            //               leading: provider.photoURL == null
            //                   ? IconButton(
            //                       icon: const Icon(Icons.remove),
            //                       onPressed: () =>
            //                           widget.user!.unlink(provider.providerId),
            //                     )
            //                   : Image.network(provider.photoURL!),
            //               title: Text(provider.providerId),
            //               subtitle: Text(''
            //                   // "${provider.uid == null ? "" : "ID: ${provider.uid}\n"}"
            //                   // "${provider.email == null ? "" : "Email: ${provider.email}\n"}"
            //                   // "${provider.phoneNumber == null ? "" : "Phone number: ${provider.phoneNumber}\n"}"
            //                   // "${provider.displayName == null ? "" : "Name: ${provider.displayName}\n"}",
            //                   ),
            //             ),
            //           ),
            //         ),
            //     ],
            //   ),
            Visibility(
              visible: widget.user != null,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => widget.user!.reload(),
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) =>
                            UpdateUserDialog(user: widget.user),
                      ),
                      icon: const Icon(Icons.text_snippet),
                    ),
                    IconButton(
                      onPressed: () => widget.user!.delete(),
                      icon: const Icon(Icons.delete_forever),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.user?.isAnonymous ?? false)
              ElevatedButton(
                onPressed: () async {
                  final account = await GoogleSignIn().signIn();

                  log(account?.toString() ?? '');

                  await widget.user!.linkWithCredential(
                    GoogleAuthProvider.credential(
                      idToken: (await account!.authentication).idToken,
                      accessToken: (await account.authentication).accessToken,
                    ),
                  );
                },
                child: const Text('link with Google'),
              ),
          ],
        ),
      ),
    );
  }
}

class UpdateUserDialog extends StatefulWidget {
  const UpdateUserDialog({Key? key, this.user}) : super(key: key);

  final User? user;

  @override
  // ignore: library_private_types_in_public_api
  _UpdateUserDialogState createState() => _UpdateUserDialogState();
}

class _UpdateUserDialogState extends State<UpdateUserDialog> {
  TextEditingController? _nameController;
  TextEditingController? _urlController;

  @override
  void initState() {
    _nameController = TextEditingController(text: widget.user!.displayName);
    _urlController = TextEditingController(text: widget.user!.photoURL);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update profile'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextFormField(
              controller: _nameController,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'displayName'),
            ),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'photoURL'),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autocorrect: false,
              validator: (String? value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.parse(value);
                  if (uri.isAbsolute) {
                    //You can get the data with dart:io or http and check it here
                    return null;
                  }
                  return 'Faulty URL!';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.user!.updateDisplayName(_nameController!.text);
            widget.user!.updatePhotoURL(
              _urlController!.text.isEmpty ? null : _urlController!.text,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        )
      ],
    );
  }

  @override
  void dispose() {
    _nameController!.dispose();
    _urlController!.dispose();
    super.dispose();
  }
}

class _EmailPasswordForm extends StatefulWidget {
  const _EmailPasswordForm({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<_EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                child: const Text(
                  'Sign in with email and password',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
                obscureText: true,
              ),
              Container(
                padding: const EdgeInsets.only(top: 16),
                alignment: Alignment.center,
                child: SignInButton(
                  Buttons.Email,
                  text: 'Sign In',
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _signInWithEmailAndPassword();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Example code of how to sign in with email and password.
  Future<void> _signInWithEmailAndPassword() async {
    try {
      final user = (await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ))
          .user!;
      ScaffoldSnackbar.of(context).show('${user.email} signed in');
    } catch (e) {
      ScaffoldSnackbar.of(context)
          .show('Failed to sign in with Email & Password');
    }
  }
}

class _EmailLinkSignInSection extends StatefulWidget {
  const _EmailLinkSignInSection({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmailLinkSignInSectionState();
}

class _EmailLinkSignInSectionState extends State<_EmailLinkSignInSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  String _email = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                child: const Text(
                  'Test sign in with email and link',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (String? value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email.';
                  }
                  return null;
                },
              ),
              Container(
                padding: const EdgeInsets.only(top: 16),
                alignment: Alignment.center,
                child: SignInButtonBuilder(
                  icon: Icons.insert_link,
                  text: 'Sign In',
                  backgroundColor: Colors.blueGrey[700]!,
                  onPressed: () async {
                    await _signInWithEmailAndLink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndLink() async {
    try {
      _email = _emailController.text;

      await _auth.sendSignInLinkToEmail(
        email: _email,
        actionCodeSettings: ActionCodeSettings(
          url:
              'https://react-native-firebase-testing.firebaseapp.com/emailSignin',
          handleCodeInApp: true,
          iOSBundleId: 'io.flutter.plugins.firebaseAuthExample',
          androidPackageName: 'io.flutter.plugins.firebaseauthexample',
        ),
      );

      ScaffoldSnackbar.of(context).show('An email has been sent to $_email');
    } catch (e) {
      print(e);
      ScaffoldSnackbar.of(context).show('Sending email failed');
    }
  }
}

class _AnonymouslySignInSection extends StatefulWidget {
  const _AnonymouslySignInSection({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnonymouslySignInSectionState();
}

class _AnonymouslySignInSectionState extends State<_AnonymouslySignInSection> {
  bool? _success;
  final _userID = '';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: const Text(
                'Test sign in anonymously',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: SignInButtonBuilder(
                text: 'Sign In',
                icon: Icons.person_outline,
                backgroundColor: Colors.deepPurple,
                onPressed: _signInAnonymously,
              ),
            ),
            Visibility(
              visible: _success != null,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _success == null
                      ? ''
                      : (_success!
                          ? 'Successfully signed in, uid: $_userID'
                          : 'Sign in failed'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Example code of how to sign in anonymously.
  Future<void> _signInAnonymously() async {
    try {
      final user = (await _auth.signInAnonymously()).user!;
      ScaffoldSnackbar.of(context)
          .show('Signed in Anonymously as user ${user.uid}');
    } catch (e) {
      ScaffoldSnackbar.of(context).show('Failed to sign in Anonymously');
    }
  }
}

class _PhoneSignInSection extends StatefulWidget {
  const _PhoneSignInSection({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PhoneSignInSectionState();
}

class _PhoneSignInSectionState extends State<_PhoneSignInSection> {
  final _phoneNumberController = TextEditingController();
  final _smsController = TextEditingController();

  String _message = '';
  late String _verificationId;
  ConfirmationResult? webConfirmationResult;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                alignment: Alignment.center,
                child: const Text(
                  'Test sign in with phone number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (+x xxx-xxx-xxxx)',
                  ),
                  validator: (String? value) {
                    if (value!.isEmpty) {
                      return 'Phone number (+x xxx-xxx-xxxx)';
                    }
                    return null;
                  },
                ),
              ),
              Container(
                alignment: Alignment.center,
                child: SignInButtonBuilder(
                  padding: const EdgeInsets.only(top: 16),
                  icon: Icons.contact_phone,
                  backgroundColor: Colors.deepOrangeAccent[700]!,
                  text: 'Verify Number',
                  onPressed: _verifyWebPhoneNumber,
                ),
              ),
              TextField(
                controller: _smsController,
                decoration:
                    const InputDecoration(labelText: 'Verification code'),
              ),
              Container(
                padding: const EdgeInsets.only(top: 16),
                alignment: Alignment.center,
                child: SignInButtonBuilder(
                  icon: Icons.phone,
                  backgroundColor: Colors.deepOrangeAccent[400]!,
                  onPressed: _confirmCodeWeb,
                  text: 'Sign In',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: const Text(
                'Test sign in with phone number',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone number (+x xxx-xxx-xxxx)',
              ),
              validator: (String? value) {
                if (value!.isEmpty) {
                  return 'Phone number (+x xxx-xxx-xxxx)';
                }
                return null;
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: SignInButtonBuilder(
                icon: Icons.contact_phone,
                backgroundColor: Colors.deepOrangeAccent[700]!,
                text: 'Verify Number',
                onPressed: _verifyPhoneNumber,
              ),
            ),
            TextField(
              controller: _smsController,
              decoration: const InputDecoration(labelText: 'Verification code'),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: SignInButtonBuilder(
                icon: Icons.phone,
                backgroundColor: Colors.deepOrangeAccent[400]!,
                onPressed: _signInWithPhoneNumber,
                text: 'Sign In',
              ),
            ),
            Visibility(
              visible: _message.isNotEmpty,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _verifyWebPhoneNumber() async {
    final confirmationResult =
        await _auth.signInWithPhoneNumber(_phoneNumberController.text);

    webConfirmationResult = confirmationResult;
  }

  Future<void> _confirmCodeWeb() async {
    if (webConfirmationResult != null) {
      try {
        await webConfirmationResult!.confirm(_smsController.text);
      } catch (e) {
        ScaffoldSnackbar.of(context).show('Failed to sign in: ${e.toString()}');
      }
    } else {
      ScaffoldSnackbar.of(context)
          .show('Please input sms code received after verifying phone number');
    }
  }

  // Example code of how to verify phone number
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _message = '';
    });

    Future verificationCompleted(
      PhoneAuthCredential phoneAuthCredential,
    ) async {
      await _auth.signInWithCredential(phoneAuthCredential);
      ScaffoldSnackbar.of(context).show(
        'Phone number automatically verified and user signed in: $phoneAuthCredential',
      );
    }

    void verificationFailed(FirebaseAuthException authException) {
      setState(() {
        _message =
            'Phone number verification failed. Code: ${authException.code}. '
            'Message: ${authException.message}';
      });
    }

    Future<PhoneCodeSent?> codeSent(
      String verificationId, [
      int? forceResendingToken,
    ]) async {
      ScaffoldSnackbar.of(context)
          .show('Please check your phone for the verification code.');

      _verificationId = verificationId;
    }

    PhoneCodeAutoRetrievalTimeout? codeAutoRetrievalTimeout(
      String verificationId,
    ) {
      _verificationId = verificationId;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneNumberController.text,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      ScaffoldSnackbar.of(context).show('Failed to Verify Phone Number: $e');
    }
  }

  // Example code of how to sign in with phone.
  Future<void> _signInWithPhoneNumber() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _smsController.text,
      );
      final user = (await _auth.signInWithCredential(credential)).user!;
      ScaffoldSnackbar.of(context)
          .show('Successfully signed in UID: ${user.uid}');
    } catch (e) {
      print(e);
      ScaffoldSnackbar.of(context).show('Failed to sign in');
    }
  }
}

class _OtherProvidersSignInSection extends StatefulWidget {
  const _OtherProvidersSignInSection({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _OtherProvidersSignInSectionState();
}

class _OtherProvidersSignInSectionState
    extends State<_OtherProvidersSignInSection> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _tokenSecretController = TextEditingController();

  int? _selection = 0;
  bool _showAuthSecretTextField = false;
  bool _showProviderTokenField = true;
  String _provider = 'GitHub';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              child: const Text(
                'Social Authentication',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: kIsWeb
                  ? const Text(
                      'When using Flutter Web, API keys are configured through the '
                      'Firebase Console. The below providers demonstrate how this works',
                    )
                  : const Text(
                      'We do not provide an API to obtain the token for below providers apart from Google '
                      'Please use a third party service to obtain token for other providers.',
                    ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ListTile(
                    title: const Text('GitHub'),
                    leading: Radio<int>(
                      value: 0,
                      groupValue: _selection,
                      onChanged: _handleRadioButtonSelected,
                    ),
                  ),
                  Visibility(
                    visible: !kIsWeb,
                    child: ListTile(
                      title: const Text('Facebook'),
                      leading: Radio<int>(
                        value: 1,
                        groupValue: _selection,
                        onChanged: _handleRadioButtonSelected,
                      ),
                    ),
                    // ListTile(
                    //   title: const Text('Google'),
                    //   leading: Radio<int>(
                    //     value: 3,
                    //     groupValue: _selection,
                    //     onChanged: _handleRadioButtonSelected,
                    //   ),
                    // ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: _showProviderTokenField && !kIsWeb,
              child: TextField(
                controller: _tokenController,
                decoration:
                    const InputDecoration(labelText: "Enter provider's token"),
              ),
            ),
            Visibility(
              visible: _showAuthSecretTextField && !kIsWeb,
              child: TextField(
                controller: _tokenSecretController,
                decoration: const InputDecoration(
                  labelText: "Enter provider's authTokenSecret",
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 16),
              alignment: Alignment.center,
              child: SignInButton(
                _provider == 'GitHub'
                    ? Buttons.GitHub
                    : _provider == 'Facebook'
                        ? Buttons.Facebook
                        : _provider == 'Twitter'
                            ? Buttons.Twitter
                            : Buttons.GoogleDark,
                text: 'Sign In',
                onPressed: _signInWithOtherProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRadioButtonSelected(int? value) {
    setState(() {
      _selection = value;

      switch (_selection) {
        case 0:
          {
            _provider = 'GitHub';
            _showAuthSecretTextField = false;
            _showProviderTokenField = true;
          }
          break;

        case 1:
          {
            _provider = 'Facebook';
            _showAuthSecretTextField = false;
            _showProviderTokenField = true;
          }
          break;

        case 2:
          {
            _provider = 'Twitter';
            _showAuthSecretTextField = true;
            _showProviderTokenField = true;
          }
          break;

        default:
          {
            _provider = 'Google';
            _showAuthSecretTextField = false;
            _showProviderTokenField = false;
          }
      }
    });
  }

  void _signInWithOtherProvider() {
    switch (_selection) {
      case 0:
        _signInWithGithub();
        break;
      case 1:
        _signInWithFacebook();
        break;
      case 2:
        _signInWithTwitter();
        break;
      default:
      // _signInWithGoogle();
    }
  }

  /// Example code of how to sign in with Github.
  Future<void> _signInWithGithub() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        final githubProvider = GithubAuthProvider();
        userCredential = await _auth.signInWithPopup(githubProvider);
      } else {
        final AuthCredential credential = GithubAuthProvider.credential(
          _tokenController.text,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user!;
      ScaffoldSnackbar.of(context).show('Sign In ${user.uid} with GitHub');
    } catch (e) {
      print(e);
      ScaffoldSnackbar.of(context).show('Failed to sign in with GitHub: $e');
    }
  }

  // Example code of how to sign in with Facebook.
  Future<void> _signInWithFacebook() async {
    try {
      final AuthCredential credential = FacebookAuthProvider.credential(
        _tokenController.text,
      );
      final user = (await _auth.signInWithCredential(credential)).user!;
      ScaffoldSnackbar.of(context).show('Sign In ${user.uid} with Facebook');
    } catch (e) {
      print(e);
      ScaffoldSnackbar.of(context).show('Failed to sign in with Facebook: $e');
    }
  }

  // Example code of how to sign in with Twitter.
  Future<void> _signInWithTwitter() async {
    try {
      late UserCredential userCredential;

      if (kIsWeb) {
        final twitterProvider = TwitterAuthProvider();
        await _auth.signInWithPopup(twitterProvider);
      } else {
        final AuthCredential credential = TwitterAuthProvider.credential(
          accessToken: _tokenController.text,
          secret: _tokenSecretController.text,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user!;
      ScaffoldSnackbar.of(context).show('Sign In ${user.uid} with Twitter');
    } catch (e) {
      print(e);
      ScaffoldSnackbar.of(context).show('Failed to sign in with Twitter: $e');
    }
  }

  //Example code of how to sign in with Google.
  // Future<void> _signInWithGoogle() async {
  //   try {
  //     UserCredential userCredential;
  //
  //     if (kIsWeb) {
  //       var googleProvider = GoogleAuthProvider();
  //       userCredential = await _auth.signInWithPopup(googleProvider);
  //     } else {
  //       final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
  //       final GoogleSignInAuthentication googleAuth =
  //           await googleUser.authentication;
  //       final googleAuthCredential = GoogleAuthProvider.credential(
  //         accessToken: googleAuth.accessToken,
  //         idToken: googleAuth.idToken,
  //       );
  //       userCredential = await _auth.signInWithCredential(googleAuthCredential);
  //     }
  //
  //     final user = userCredential.user;
  //     Scaffold.of(context).showSnackBar(SnackBar(
  //       content: Text('Sign In ${user.uid} with Google'),
  //     ));
  //   } catch (e) {
  //     print(e);
  //     Scaffold.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Failed to sign in with Google: $e'),
  //       ),
  //     );
  //   }
  // }
}
