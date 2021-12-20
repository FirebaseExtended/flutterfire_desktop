// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// Pure Dart FirebaseAuth implementation.
class FirebaseAuth {
  FirebaseAuth._({required this.app}) {
    _api = API(
      app.options.apiKey,
      app.options.projectId,
    );

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

  // Cached instances of [FirebaseAuth].
  static final Map<String, FirebaseAuth> _firebaseAuthInstances = {};

  /// The [FirebaseApp] for this current Auth instance.
  late FirebaseApp app;

  /// Change the HTTP client for the purpose of testing.
  @visibleForTesting
  void setApiClient(http.Client client) {
    _api._setApiClient(client);
  }

  /// Returns an instance using the default [FirebaseApp].
  // ignore: prefer_constructors_over_static_methods
  static FirebaseAuth get instance {
    final defaultAppInstance = Firebase.app();

    return FirebaseAuth.instanceFor(app: defaultAppInstance);
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

  late final API _api;

  // ignore: close_sinks
  late StreamController<User?> _changeController;

  // ignore: close_sinks
  late StreamController<User?> _idTokenChangedController;

  /// The currently signed in user for this instance.
  User? currentUser;

  /// Sends events when the users sign-in state changes.
  ///
  /// If the value is `null`, there is no signed-in user.
  Stream<User?> get onAuthStateChanged {
    return _changeController.stream;
  }

  /// Sends events for changes to the signed-in user's ID token,
  /// which includes sign-in, sign-out, and token refresh events.
  ///
  /// If the value is `null`, there is no signed-in user.
  Stream<User?> get onIdTokenChanged {
    return _idTokenChangedController.stream;
  }

  /// Helper method to update currentUser and events.
  @protected
  void updateCurrentUserAndEvents(User? user) {
    _userStorage.putValue(
      '${app.options.apiKey}:${app.name}',
      {'currentUser': user?.toMap()},
    );
    currentUser = user;

    _changeController.add(user);
    _idTokenChangedController.add(user);
  }

  /// Sign in a user using email and password.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// TODO: write the codes
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await _api.signInWithEmailAndPassword(email, password);
      final userData = await _api.getCurrentUser(response['idToken']);

      // Map the json response to an actual user.
      final user = User(userData.toJson()..addAll(response), this);

      updateCurrentUserAndEvents(user);

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
      throw getException(e);
    }
  }

  /// Create new user using email and password.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `INVALID_EMAIL`
  /// - `EMAIL_EXISTS`
  /// - `OPERATION_NOT_ALLOWED`
  /// - `TOO_MANY_ATTEMPTS_TRY_LATER`
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final response =
          await _api.createUserWithEmailAndPassword(email, password);
      final userData = await _api.getCurrentUser(response['idToken']);

      // Map the json response to an actual user.
      final user = User(userData.toJson()..addAll(response), this);

      updateCurrentUserAndEvents(user);

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
      throw getException(e);
    }
  }

  /// Fetch the list of providers associated with a specified email.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `INVALID_EMAIL`: user doesn't exist
  /// - `INVALID_IDENTIFIER`: the identifier isn't a valid email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      final providers = await _api.fetchSignInMethodsForEmail(email);

      return providers;
    } catch (e) {
      throw getException(e);
    }
  }

  /// Send a password reset email.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `EMAIL_EXISTS`: The email address is already in use by another account.
  /// - `INVALID_ID_TOKEN`: The user's credential is no longer valid. The user must sign in again.
  Future sendPasswordResetEmail(String email) async {
    try {
      await _api.sendPasswordResetEmail(email);
    } catch (e) {
      throw getException(e);
    }
  }

  /// Reset user password.
  ///
  /// Requires tht the user has recently been authenticated,
  /// check [User.reauthenticateWithCredential].
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `OPERATION_NOT_ALLOWED`: Password sign-in is disabled for this project.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  /// TODO: make sure codes are correct
  Future resetUserPassword({String? newPassword, String? oldPassword}) async {
    try {
      if (currentUser != null) {
        final token = await currentUser!.getIdToken();
        await _api.resetUserPassword(token);
      } else {
        throw FirebaseAuthException(code: 'USER_NOT_FOUND');
      }
    } catch (e) {
      throw getException(e);
    }
  }

  /// Send a sign in link to email.
  ///
  /// Throws [FirebaseAuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  Future sendSignInLinkToEmail(String email, [String? continueUrl]) async {
    try {
      await _api.sendSignInLinkToEmail(email, continueUrl);
    } catch (e) {
      throw getException(e);
    }
  }

  /// Sign in anonymous users.
  ///
  /// If there's a user already sign-in anonymously, will be returned.
  ///
  /// TODO: describe exceptions
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
      final userData =
          (await _api.getCurrentUser(response['idToken'])).toJson();

      // Map the json response to an actual user.
      final user = User(userData..addAll(response), this);

      updateCurrentUserAndEvents(user);

      return UserCredential._(
          auth: this,
          additionalUserInfo: AdditionalUserInfo(isNewUser: true),
          credential: const AuthCredential(
              providerId: providerId, signInMethod: providerId));
    } catch (e) {
      throw getException(e);
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

  /// TODO
  Future<UserCredential> signInWithCredential(
    AuthCredential credential,
  ) async {
    idp.VerifyAssertionResponse response;

    if (credential is GoogleAuthCredential) {
      response = await _api.signInWithOAuthCredential(
        requestUri: app.options.authDomain,
        providerIdToken: credential.idToken!,
        providerId: credential.providerId,
      );
    } else {
      throw UnsupportedError('This credential is not supported yet.');
    }

    final userData = await _api.getCurrentUser(response.idToken!);

    // Map the json response to an actual user.
    final user = User(userData.toJson()..addAll(response.toJson()), this);

    updateCurrentUserAndEvents(user);

    return UserCredential._(
      auth: this,
      credential: credential,
      additionalUserInfo: AdditionalUserInfo(
        isNewUser: response.isNewUser ?? false,
        providerId: response.providerId,
        username: response.screenName,
        profile: {
          'displayName': response.displayName,
          'photoUrl': response.photoUrl
        },
      ),
    );
  }

  /// TODO
  Future<UserCredential> signInWithEmailLink(
      String email, String emailLink) async {
    throw UnimplementedError();
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

  /// TODO
  Future<void> verifyPhoneNumber({required String phoneNumber}) async {
    throw UnimplementedError();

    // final response = await _api.verifyPhoneNumber(phoneNumber);

    // log(response.sessionInfo!);

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

  /// Internally used to reload the current user and send events.
  @protected
  Future<Map<String, dynamic>> _reloadCurrentUser(String idToken) async {
    try {
      final response = await _api.getCurrentUser(idToken);
      return response.toJson();
    } catch (e) {
      throw getException(e);
    }
  }

  /// Sign user out by cleaning currentUser, local persistence and all streams.
  ///
  Future<void> signOut() async {
    try {
      updateCurrentUserAndEvents(null);
    } catch (exception) {
      log('$exception', name: 'FirebaseAuth/signOut');

      rethrow;
    }
  }

  /// Refresh a user ID token using the refreshToken,
  /// will refresh even if the token hasn't expired.
  @protected
  Future<String?> refreshIdToken() async {
    try {
      if (currentUser != null) {
        return await _api.refreshIdToken(currentUser!.refreshToken!);
      } else {
        throw FirebaseAuthException(code: 'NOT_SIGNED_IN');
      }
    } on HttpException catch (_) {
      rethrow;
    } catch (exception) {
      rethrow;
    }
  }

  /// Use the emulator to perform all requests,
  /// check your terminal for the port being used.
  ///
  /// You must start the emulator in order to use it,
  /// the mthod will throw if there's no running emulator,
  /// see:
  /// https://firebase.google.com/docs/emulator-suite/install_and_configure#install_the_local_emulator_suite
  Future<Map> useAuthEmulator(
      {String host = 'localhost', int port = 9099}) async {
    try {
      return await _api.useEmulator(host, port);
    } catch (e) {
      throw getException(e);
    }
  }

  ///
  @protected
  Exception getException(Object e) {
    if (e is idp.DetailedApiRequestError) {
      var errorCode = e.message ?? '';

      // Solves a problem with incosistent error codes coming from the server.
      if (errorCode.contains(' ')) {
        errorCode = errorCode.split(' ').first;
      }

      final authException = FirebaseAuthException(code: errorCode);
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
