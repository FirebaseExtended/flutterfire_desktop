// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// Pure Dart FirebaseAuth implementation.
class FirebaseAuth {
  FirebaseAuth._({required this.app}) {
    _api = API(APIConfig(app.options.apiKey, app.options.projectId));

    _idTokenChangedController = StreamController<User?>.broadcast(sync: true);
    _changeController = StreamController<User?>.broadcast(sync: true);

    if (_localUser() != null) {
      currentUser = User(_localUser()!, this);
    }
  }

  /// Returns an instance using a specified [FirebaseApp].
  factory FirebaseAuth.instanceFor({required FirebaseApp app}) {
    return _firebaseAuthInstances.putIfAbsent(app.name, () {
      return FirebaseAuth._(app: app);
    });
  }

  /// Returns an instance using the default [FirebaseApp].
  // ignore: prefer_constructors_over_static_methods
  static FirebaseAuth get instance {
    final defaultAppInstance = Firebase.app();

    return FirebaseAuth.instanceFor(app: defaultAppInstance);
  }

  // Cached instances of [FirebaseAuth].
  static final Map<String, FirebaseAuth> _firebaseAuthInstances = {};

  /// The [FirebaseApp] for this current Auth instance.
  late FirebaseApp app;

  /// Initialized [API] instance linked to this instance.
  late final API _api;

  /// Change the HTTP client for the purpose of testing.
  @visibleForTesting
  void setApiClient(http.Client client) {
    _api.setApiClient(client);
  }

  StorageBox<Object> get _userStorage =>
      StorageBox.instanceOf(app.options.projectId);

  Map<String, dynamic>? _localUser() {
    try {
      return (_userStorage.getValue('${app.options.apiKey}:${app.name}')
          as Map<String, dynamic>)['currentUser'];
    } catch (e) {
      return null;
    }
  }

  // ignore: close_sinks
  late StreamController<User?> _changeController;

  // ignore: close_sinks
  late StreamController<User?> _idTokenChangedController;

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], or [idTokenChanges] to
  /// subscribe to updates.
  User? currentUser;

  /// Sends events when the users sign-in state changes.
  ///
  /// If the value is `null`, there is no signed-in user.
  Stream<User?> authStateChanges() async* {
    yield currentUser;
    yield* _changeController.stream;
  }

  /// Sends events for changes to the signed-in user's ID token,
  /// which includes sign-in, sign-out, and token refresh events.
  ///
  /// If the value is `null`, there is no signed-in user.
  Stream<User?> idTokenChanges() async* {
    yield currentUser;
    yield* _idTokenChangedController.stream;
  }

  /// Helper method to update currentUser and events.
  @protected
  void _updateCurrentUserAndEvents(User? user,
      [bool authStateChanged = false]) {
    _userStorage.putValue(
      '${app.options.apiKey}:${app.name}',
      {'currentUser': user?.toMap()},
    );

    currentUser = user;

    if (authStateChanged) {
      _changeController.add(user);
    }

    _idTokenChangedController.add(user);
  }

  /// Attempts to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], or [idTokenChanges] stream listeners.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `invalid-email`
  ///   - Thrown if the email address is not valid.
  /// - `user-disabled`
  ///   - Thrown if the user corresponding to the given email has been disabled.
  /// - `user-not-found`
  ///   - Thrown if there is no user corresponding to the given email.
  /// - `wrong-password`
  ///   - Thrown if the password is invalid for the given email, or the account
  ///     corresponding to the email does not have a password set.
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await _api.signInWithEmailAndPassword(email, password);
      final userData = await _api.getCurrentUser(response.idToken);

      // Map the json response to an actual user.
      final user = User(userData.toJson()..addAll(response.toJson()), this);

      _updateCurrentUserAndEvents(user, true);

      // Make a credential object based on the current sign-in method.
      return UserCredential._(
        auth: this,
        credential:
            EmailAuthProvider.credential(email: email, password: password),
        additionalUserInfo: AdditionalUserInfo(
            isNewUser: false,
            providerId: EmailAuthProvider.PROVIDER_ID,
            username: userData.screenName,
            profile: {
              'displayName': userData.displayName,
              'photoUrl': userData.photoUrl
            }),
      );
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Tries to create a new user account with the given email address and
  /// password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `email-already-in-use`
  ///   - Thrown if there already exists an account with the given email address.
  /// - `invalid-email`
  ///   - Thrown if the email address is not valid.
  /// - `operation-not-allowed`
  ///   - Thrown if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - `weak-password`
  ///   - Thrown if the password is not strong enough.
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final response =
          await _api.createUserWithEmailAndPassword(email, password);
      final userData = await _api.getCurrentUser(response.idToken);

      // Map the json response to an actual user.
      final user = User(userData.toJson()..addAll(response.toJson()), this);

      _updateCurrentUserAndEvents(user, true);

      return UserCredential._(
        auth: this,
        credential:
            EmailAuthProvider.credential(email: email, password: password),
        additionalUserInfo: AdditionalUserInfo(
            isNewUser: true,
            providerId: EmailAuthProvider.PROVIDER_ID,
            username: userData.screenName,
            profile: {
              'displayName': userData.displayName,
              'photoUrl': userData.photoUrl
            }),
      );
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Returns a list of sign-in methods that can be used to sign in a given
  /// user (identified by its main email address).
  ///
  /// This method is useful when you support multiple authentication mechanisms
  /// if you want to implement an email-first authentication flow.
  ///
  /// An empty `List` is returned if the user could not be found.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `invalid-email`
  ///   - Thrown if the email address is not valid.
  /// - `invalid-identifier`
  ///   - Thrown if the identifier isn't a valid email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      final providers = await _api.fetchSignInMethodsForEmail(email);

      return providers;
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Sends a password reset email to the given email address.
  ///
  /// To complete the password reset, call [confirmPasswordReset] with the code supplied
  /// in the email sent to the user, along with the new password specified by the user.
  ///
  /// May throw a [FirebaseAuthException] with the following error codes:
  /// - `email-exists`
  ///   - The email address is already in use by another account.
  /// - `invalid-id-token`
  ///   - The user's credential is no longer valid. The user must sign in again.
  Future<String> sendPasswordResetEmail(
      {required String email, String? continueUrl}) async {
    try {
      return await _api.sendPasswordResetEmail(email);
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Completes the password reset process, given a confirmation code and new
  /// password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `expired-action-code`
  ///   - Thrown if the action code has expired.
  /// - `invalid-action-code`
  ///   - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - `user-disabled`
  ///   - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - `user-not-found`
  ///   - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  /// - `weak-password`
  ///   - Thrown if the new password is not strong enough.
  Future<String> confirmPasswordReset(String? code, String? newPassword) async {
    try {
      return await _api.confirmPasswordReset(code, newPassword);
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Checks a password reset code sent to the user by email or other
  /// out-of-band mechanism.
  ///
  /// Returns the user's email address if valid.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `expired-action-code`
  ///   - Thrown if the password reset code has expired.
  /// - `invalid-action-code`
  ///   - Thrown if the password reset code is invalid. This can happen if the
  ///    code is malformed or has already been used.
  /// - `user-disabled`
  ///   - Thrown if the user corresponding to the given email has been disabled.
  /// - `user-not-found`
  ///   - Thrown if there is no user corresponding to the password reset code.
  ///    This may have happened if the user was deleted between when the code
  ///    was issued and when this method was called.
  Future<String> verifyPasswordResetCode(String? code) async {
    try {
      return await _api.confirmPasswordReset(code, null);
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Send a sign in link to email.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `email-not-found`
  ///   - user doesn't exist
  Future sendSignInLinkToEmail(String email, [String? continueUrl]) async {
    try {
      await _api.sendSignInLinkToEmail(email, continueUrl);
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `operation-not-allowed`
  ///   - Thrown if anonymous accounts are not enabled. Enable anonymous accounts
  ///     in the Firebase Console, under the Auth tab.
  Future<UserCredential> signInAnonymously() async {
    const providerId = 'anonymous';

    try {
      if (currentUser?.isAnonymous ?? false) {
        return UserCredential._(
          auth: this,
          credential: const AuthCredential(
            providerId: providerId,
            signInMethod: providerId,
          ),
          additionalUserInfo: AdditionalUserInfo(isNewUser: false),
        );
      }

      final response = await _api.signInAnonymously();
      final userData = (await _api.getCurrentUser(response.idToken)).toJson();

      // Map the json response to an actual user.
      final user = User(userData..addAll(response.toJson()), this);

      _updateCurrentUserAndEvents(user, true);

      return UserCredential._(
          auth: this,
          additionalUserInfo: AdditionalUserInfo(isNewUser: true),
          credential: const AuthCredential(
              providerId: providerId, signInMethod: providerId));
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Authenticates a Firebase client using a popup-based OAuth authentication
  /// flow.
  ///
  /// If succeeds, returns the signed in user along with the provider's
  /// credential.
  ///
  /// This method is only available on web based platforms.
  Future<UserCredential> signInWithPopup() async {
    // check if running on Web
    if (identical(0, 0.0)) {
      throw UnimplementedError(
        'signInWithPopup() is only supported on web based platforms',
      );
    }

    throw UnimplementedError('signInWithPop() is not yet implemented.');
  }

  /// Asynchronously signs in to Firebase with the given 3rd-party credentials
  /// (e.g. a Facebook login Access Token, a Google ID Token/Access Token pair,
  /// etc.) and returns additional identity provider data.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], or [idTokenChanges] stream listeners.
  ///
  /// If the user doesn't have an account already, one will be created
  /// automatically.
  ///
  /// **Important**: You must enable the relevant accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - `account-exists-with-different-credential`
  ///   - Thrown if there already exists an account with the email address
  ///    asserted by the credential.
  ///    Resolve this by calling [fetchSignInMethodsForEmail] and then asking
  ///    the user to sign in using one of the returned providers.
  ///    Once the user is signed in, the original credential can be linked to
  ///    the user with [linkWithCredential].
  /// - `invalid-credential`
  ///   - Thrown if the credential is malformed or has expired.
  /// - `operation-not-allowed`
  ///   - Thrown if the type of account corresponding to the credential is not
  ///    enabled. Enable the account type in the Firebase Console, under the
  ///    Auth tab.
  /// - `user-disabled`
  ///   - Thrown if the user corresponding to the given credential has been
  ///    disabled.
  /// - `user-not-found`
  ///   - Thrown if signing in with a credential from [EmailAuthProvider.credential]
  ///    and there is no user corresponding to the given email.
  /// - `wrong-password`
  ///   - Thrown if signing in with a credential from [EmailAuthProvider.credential]
  ///    and the password is invalid for the given email, or if the account
  ///    corresponding to the email does not have a password set.
  /// - `invalid-code`
  ///   - Thrown if the credential is a `PhoneAuthProvider.credential` and the
  ///    verification code of the credential is not valid.
  /// - `invalid-verification-id`
  ///   - Thrown if the credential is a `PhoneAuthProvider.credential` and the
  ///    verification ID of the credential is not valid.
  Future<UserCredential> signInWithCredential(
    AuthCredential credential,
  ) async {
    try {
      Map<String, dynamic> response;

      if (credential is GoogleAuthCredential) {
        assert(app.options.authDomain != null,
            'You should provide authDomain when trying to add Google as auth provider.');

        response = (await _api.signInWithOAuthCredential(
          requestUri: app.options.authDomain,
          providerId: credential.providerId,
          providerIdToken: credential.idToken,
          providerAccessToken: credential.accessToken,
        ))
            .toJson();
      } else if (credential is TwitterAuthCredential) {
        response = (await _api.signInWithOAuthCredential(
          requestUri: app.options.authDomain,
          providerId: credential.providerId,
          providerAccessToken: credential.accessToken,
          providerSecret: credential.secret,
        ))
            .toJson();
      } else if (credential is FacebookAuthCredential) {
        response = (await _api.signInWithOAuthCredential(
          requestUri: app.options.authDomain,
          providerId: credential.providerId,
          providerAccessToken: credential.accessToken,
        ))
            .toJson();
      } else {
        throw UnsupportedError('This credential is not supported yet.');
      }

      final userData = await _api.getCurrentUser(response['idToken']);

      // Map the json response to an actual user.
      final user = User(userData.toJson()..addAll(response), this);

      _updateCurrentUserAndEvents(user, true);

      return UserCredential._(
        auth: this,
        credential: credential,
        additionalUserInfo: AdditionalUserInfo(
          isNewUser: response['isNewUser'] ?? false,
          providerId: credential.providerId,
          username: userData.screenName,
          profile: {
            'displayName': userData.displayName,
            'photoUrl': userData.photoUrl
          },
        ),
      );
    } catch (e) {
      throw _getException(e);
    }
  }

  /// TODO
  Future<UserCredential> signInWithEmailLink(
      String email, String emailLink) async {
    throw UnimplementedError('signInWithEmailLink() is not yet implemented.');

    // final response = await _api.signInWithEmailLink(
    //     email, Uri.parse(emailLink).queryParameters['oobCode']!);

    // final userData = await _api.getCurrentUser(response.idToken!);

    // // Map the json response to an actual user.
    // final user = User(userData.toJson()..addAll(response.toJson()), this);

    // updateCurrentUserAndEvents(user);

    // return UserCredential._(
    //   auth: this,
    //   credential: EmailAuthProvider.credentialWithLink(
    //       email: email, emailLink: emailLink),
    // );
  }

  /// Starts a phone number verification process for the given phone number.
  ///
  /// This method is used to verify that the user-provided phone number belongs
  /// to the user. Firebase sends a code via SMS message to the phone number,
  /// where you must then prompt the user to enter the code. The code can be
  /// combined with the verification ID to create a [PhoneAuthProvider.credential]
  /// which you can then use to sign the user in, or link with their account (
  /// see [signInWithCredential] or [User.linkWithCredential]).
  Future<ConfirmationResult> signInWithPhoneNumber(String phoneNumber,
      [verifier.RecaptchaVerifier? verifier]) async {
    try {
      final signInResponse =
          await _api.phoneAuthApiDelegate.signInWithPhoneNumber(
        phoneNumber,
        verifier: verifier,
        idToken: await currentUser?.getIdToken(),
      );
      final verificationId = signInResponse.verificationId;
      return ConfirmationResult(this, verificationId!);
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Internally used to reload the current user and send events.
  @protected
  Future<Map<String, dynamic>> _reloadCurrentUser(String idToken) async {
    try {
      final response = await _api.getCurrentUser(idToken);
      return response.toJson();
    } catch (e) {
      throw _getException(e);
    }
  }

  /// Signs out the current user.
  ///
  /// If successful, it also updates
  /// any [authStateChanges], or [idTokenChanges] stream listeners.
  Future<void> signOut() async {
    try {
      _updateCurrentUserAndEvents(null, true);
    } catch (exception) {
      log('$exception', name: 'FirebaseAuth/signOut');

      rethrow;
    }
  }

  /// Changes this instance to point to an Auth emulator running locally.
  ///
  /// Set the [host] and [port] of the local emulator, such as "localhost"
  /// with port 9099
  ///
  /// Note: Must be called immediately, prior to accessing auth methods.
  /// Do not use with production credentials as emulator traffic is not encrypted.
  ///
  /// You must start the emulator in order to use it,
  /// the method will throw a [SocketException] if there's no running emulator,
  /// see:
  /// https://firebase.google.com/docs/emulator-suite/install_and_configure#install_the_local_emulator_suite
  Future<Map> useAuthEmulator(
      {String host = 'localhost', int port = 9099}) async {
    try {
      return await _api.useEmulator(host, port);
    } catch (e) {
      throw _getException(e);
    }
  }

  @protected
  Exception _getException(Object e) {
    if (e is idp.DetailedApiRequestError) {
      var errorCode = e.message ?? '';
      String? errorMessage;

      if (e.jsonResponse?['error'] != null &&
          // ignore: avoid_dynamic_calls
          e.jsonResponse?['error']['status'] != null) {
        // ignore: avoid_dynamic_calls
        errorCode = e.jsonResponse!['error']['status'];
        errorMessage = e.message;
      }

      // Solves a problem with incosistent error codes coming from the server.
      if (errorCode.contains(' ')) {
        errorCode = errorCode.split(' ').first;
      }

      final authException =
          FirebaseAuthException(code: errorCode, message: errorMessage);
      log('${authException.message}',
          name: 'firebase_auth_dart/${authException.code}');

      return authException;
    } else if (e is Exception) {
      log('$e', name: 'firebase_auth_dart');

      return e;
    } else {
      log('$e', name: 'firebase_auth_dart');

      return Exception(e);
    }
  }
}
