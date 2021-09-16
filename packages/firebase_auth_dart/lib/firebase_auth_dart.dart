library firebase_auth_dart;

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';

/// A Dart only implmentation of FirebaseAuth for managing Firebase users.
class FirebaseAuthDart extends FirebaseAuthPlatform {
  /// Entry point for the [FirebaseAuthDart] classs.
  FirebaseAuthDart({required FirebaseApp app}) : super(appInstance: app) {
    // Create a app instance broadcast stream for both delegate listener events
    _userChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();
  }

  FirebaseAuthDart._() : super(appInstance: null);

  /// Stub initializer to allow creating an instance without
  /// registering delegates or listeners.
  ///
  // ignore: prefer_constructors_over_static_methods
  static FirebaseAuthDart get instance {
    return FirebaseAuthDart._();
  }

  @override
  UserPlatform? get currentUser;

  @override
  String? tenantId;

  static final Map<String, StreamController<UserPlatform?>>
      _userChangesListeners = <String, StreamController<UserPlatform?>>{};

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) {
    return FirebaseAuthDart(app: app);
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    return this;
  }

  @override
  Stream<UserPlatform?> userChanges() async* {
    yield currentUser;
    yield* _userChangesListeners[app.name]!.stream;
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
      String email, String password) {
    // TODO: implement signInWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future<void> applyActionCode(String code) {
    // TODO: implement applyActionCode
    throw UnimplementedError();
  }

  @override
  Stream<UserPlatform?> authStateChanges() {
    // TODO: implement authStateChanges
    throw UnimplementedError();
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) {
    // TODO: implement checkActionCode
    throw UnimplementedError();
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) {
    // TODO: implement confirmPasswordReset
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
      String email, String password) {
    // TODO: implement createUserWithEmailAndPassword
    throw UnimplementedError();
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) {
    // TODO: implement fetchSignInMethodsForEmail
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> getRedirectResult() {
    // TODO: implement getRedirectResult
    throw UnimplementedError();
  }

  @override
  Stream<UserPlatform?> idTokenChanges() {
    // TODO: implement idTokenChanges
    throw UnimplementedError();
  }

  @override
  bool isSignInWithEmailLink(String emailLink) {
    // TODO: implement isSignInWithEmailLink
    throw UnimplementedError();
  }

  @override
  // TODO: implement languageCode
  String? get languageCode => throw UnimplementedError();

  @override
  void sendAuthChangesEvent(String appName, UserPlatform? userPlatform) {
    // TODO: implement sendAuthChangesEvent
  }

  @override
  Future<void> sendPasswordResetEmail(String email,
      [ActionCodeSettings? actionCodeSettings]) {
    // TODO: implement sendPasswordResetEmail
    throw UnimplementedError();
  }

  @override
  Future<void> sendSignInLinkToEmail(
      String email, ActionCodeSettings actionCodeSettings) {
    // TODO: implement sendSignInLinkToEmail
    throw UnimplementedError();
  }

  @override
  Future<void> setLanguageCode(String languageCode) {
    // TODO: implement setLanguageCode
    throw UnimplementedError();
  }

  @override
  Future<void> setPersistence(Persistence persistence) {
    // TODO: implement setPersistence
    throw UnimplementedError();
  }

  @override
  Future<void> setSettings(
      {bool? appVerificationDisabledForTesting,
      String? userAccessGroup,
      String? phoneNumber,
      String? smsCode,
      bool? forceRecaptchaFlow}) {
    // TODO: implement setSettings
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() {
    // TODO: implement signInAnonymously
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
      AuthCredential credential) {
    // TODO: implement signInWithCredential
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) {
    // TODO: implement signInWithCustomToken
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
      String email, String emailLink) {
    // TODO: implement signInWithEmailLink
    throw UnimplementedError();
  }

  @override
  Future<ConfirmationResultPlatform> signInWithPhoneNumber(String phoneNumber,
      RecaptchaVerifierFactoryPlatform applicationVerifier) {
    // TODO: implement signInWithPhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) {
    // TODO: implement signInWithPopup
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) {
    // TODO: implement signInWithRedirect
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }

  @override
  Future<void> useAuthEmulator(String host, int port) {
    // TODO: implement useAuthEmulator
    return Future.value();
  }

  @override
  Future<String> verifyPasswordResetCode(String code) {
    // TODO: implement verifyPasswordResetCode
    throw UnimplementedError();
  }

  @override
  Future<void> verifyPhoneNumber(
      {required String phoneNumber,
      required PhoneVerificationCompleted verificationCompleted,
      required PhoneVerificationFailed verificationFailed,
      required PhoneCodeSent codeSent,
      required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
      Duration timeout = const Duration(seconds: 30),
      int? forceResendingToken,
      String? autoRetrievedSmsCodeForTesting}) {
    // TODO: implement verifyPhoneNumber
    throw UnimplementedError();
  }
}
