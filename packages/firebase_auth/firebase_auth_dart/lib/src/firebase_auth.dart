// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// Pure Dart service wrapper around the Identity Platform REST API.
///
/// https://cloud.google.com/identity-platform/docs/use-rest-api
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
  /// Throws [AuthException] with following possible codes:
  /// TODO: write the codes
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final _userMap = await _api.signInWithEmailAndPassword(email, password);

      // Map the json response to an actual user.
      final user = User(_userMap, this);

      updateCurrentUserAndEvents(user);

      final providerId = AuthProvider.password.providerId;

      // Make a credential object based on the current sign-in method.
      return UserCredential(
        user: user,
        credential: AuthCredential(
          providerId: providerId,
          signInMethod: providerId,
        ),
        additionalUserInfo: AdditionalUserInfo(isNewUser: false),
      );
    } catch (e) {
      throw getException(e);
    }
  }

  /// Create new user using email and password.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `INVALID_EMAIL`
  /// - `EMAIL_EXISTS`
  /// - `OPERATION_NOT_ALLOWED`
  /// - `TOO_MANY_ATTEMPTS_TRY_LATER`
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final _response =
          await _api.createUserWithEmailAndPassword(email, password);

      final user = User(_response, this);
      updateCurrentUserAndEvents(user);

      final providerId = AuthProvider.password.providerId;

      return UserCredential(
        user: user,
        credential: AuthCredential(
          providerId: providerId,
          signInMethod: providerId,
        ),
        additionalUserInfo: AdditionalUserInfo(isNewUser: true),
      );
    } catch (e) {
      throw getException(e);
    }
  }

  /// Fetch the list of providers associated with a specified email.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `INVALID_EMAIL`: user doesn't exist
  /// - `INVALID_IDENTIFIER`: the identifier isn't a valid email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      final _providers = await _api.fetchSignInMethodsForEmail(email);

      return _providers;
    } catch (e) {
      throw getException(e);
    }
  }

  /// Send a password reset email.
  ///
  /// Throws [AuthException] with following possible codes:
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
  /// Throws [AuthException] with following possible codes:
  /// - `OPERATION_NOT_ALLOWED`: Password sign-in is disabled for this project.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  /// TODO: make sure codes are correct
  Future resetUserPassword({String? newPassword, String? oldPassword}) async {
    try {
      if (currentUser != null) {
        final token = await currentUser!.getIdToken();
        await _api.resetUserPassword(token!);
      } else {
        throw AuthException.fromErrorCode(ErrorCode.userNotSignedIn);
      }
    } catch (e) {
      throw getException(e);
    }
  }

  /// Send a sign in link to email.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  Future sendSignInLinkToEmail(String email) async {
    try {
      await _api.sendSignInLinkToEmail(email);
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
    final providerId = AuthProvider.anonymous.providerId;

    try {
      if (currentUser?.isAnonymous ?? false) {
        return UserCredential(
          user: currentUser,
          credential: AuthCredential(
            providerId: providerId,
            signInMethod: providerId,
          ),
          additionalUserInfo: AdditionalUserInfo(isNewUser: false),
        );
      }

      final _response = await _api.signInAnonymously();

      final _data = _response;

      _data['isAnonymous'] = true;

      final user = User(_data, this);
      updateCurrentUserAndEvents(user);

      return UserCredential(
        user: user,
        credential: AuthCredential(
          providerId: providerId,
          signInMethod: providerId,
        ),
        additionalUserInfo: AdditionalUserInfo(isNewUser: true),
      );
    } catch (e) {
      throw getException(e);
    }
  }

  /// Update user's email.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  @protected
  Future<Map<String, dynamic>> reloadCurrentUser(String idToken) async {
    try {
      final userMap = await _api.reloadCurrentUser(idToken);
      return userMap;
    } catch (e) {
      throw getException(e);
    }
  }

  /// Update user's photoURL.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  @protected
  Future updateProfile(Map<String, dynamic> newProfile, String idToken) async {
    try {
      await _api.updateProfile(newProfile, idToken, currentUser!.uid);
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
      log('$exception', name: 'DartAuth/signOut');

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
        throw AuthException.fromErrorCode(ErrorCode.userNotSignedIn);
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
    if (e is DetailedApiRequestError) {
      final authException = AuthException.fromErrorCode(e.message);
      log('$authException', name: 'firebase_auth_dart/${authException.code}');

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
