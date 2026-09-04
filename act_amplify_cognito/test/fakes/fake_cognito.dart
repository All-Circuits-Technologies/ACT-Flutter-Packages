// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// The name of one call of a test to the authentication of the cloud.
typedef AuthCall = ({String name, Map<String, Object?> arguments});

/// What a session of a test answers instead of the tokens Cognito signs.
const _noTokens = SessionExpiredException("A test has no tokens of its own");

/// The authentication of a cloud, answered by the test.
///
/// It records the calls it was asked for and answers what the test lined up, or throws the
/// exception the test gave it instead of answering. Cognito itself opens a session with a server,
/// which no test can do, so this is what stands in for it.
class FakeAuthPlugin extends AuthPluginInterface {
  /// The key the plugin is added to the authentication of the cloud under.
  static const pluginKey = "fakeCognito";

  /// The calls which were asked for, in the order they were asked.
  final List<AuthCall> calls = [];

  /// The step the sign in of the cloud answers with.
  AuthSignInStep signInStep = AuthSignInStep.done;

  /// The step the sign up of the cloud answers with.
  AuthSignUpStep signUpStep = AuthSignUpStep.done;

  /// The step the update of an attribute answers with.
  AuthUpdateAttributeStep updateAttributeStep = AuthUpdateAttributeStep.done;

  /// The session of the cloud, of a user who is signed in unless the test says otherwise.
  bool isSignedIn = true;

  /// The attributes of the user of the cloud.
  List<AuthUserAttribute> attributes = const [];

  /// The exception the cloud throws instead of answering, when the test gave one.
  AuthException? exception;

  /// The name of the call the exception is thrown on, or null for every call.
  String? exceptionOn;

  /// Class constructor
  FakeAuthPlugin();

  /// Adds the plugin to the authentication of the cloud, in place of the one of Cognito.
  ///
  /// The categories of Amplify are shared by the whole test file, so the caller has to forget the
  /// plugins of the authentication once the test is over.
  static Future<FakeAuthPlugin> install() async {
    final plugin = FakeAuthPlugin();
    await Amplify.Auth.addPlugin(plugin, authProviderRepo: AmplifyAuthProviderRepository());

    return plugin;
  }

  /// The names of the calls which were asked for, in the order they were asked.
  List<String> get callNames => calls.map((call) => call.name).toList();

  /// The arguments of the call named [name], when it was asked for once only.
  Map<String, Object?> argumentsOf(String name) =>
      calls.singleWhere((call) => call.name == name).arguments;

  /// Records the call [name] with its [arguments], and throws what the test lined up for it.
  void _record(String name, [Map<String, Object?> arguments = const {}]) {
    calls.add((name: name, arguments: arguments));

    final error = exception;
    if (error != null && (exceptionOn == null || exceptionOn == name)) {
      throw error;
    }
  }

  @override
  Future<SignInResult> signIn({
    required String username,
    String? password,
    SignInOptions? options,
  }) async {
    _record("signIn", {"username": username, "password": password});

    return _signInResult();
  }

  @override
  Future<SignInResult> confirmSignIn({
    required String confirmationValue,
    ConfirmSignInOptions? options,
  }) async {
    _record("confirmSignIn", {"confirmationValue": confirmationValue});

    return _signInResult();
  }

  /// {@macro amplify_core.AuthPluginInterface.signOut}
  ///
  /// The results of a sign out are built by Cognito itself: both the one which says that it went
  /// through and the one which says that it did not have a constructor a test can call, so the
  /// sign out is out of reach of these tests.
  @override
  Future<SignOutResult> signOut({SignOutOptions? options}) async {
    _record("signOut");

    throw UnimplementedError("A test cannot build the result of a sign out");
  }

  @override
  Future<SignUpResult> signUp({
    required String username,
    required String password,
    SignUpOptions? options,
  }) async {
    _record("signUp", {
      "username": username,
      "password": password,
      "attributes": options?.userAttributes,
    });

    return CognitoSignUpResult(
      isSignUpComplete: signUpStep == AuthSignUpStep.done,
      nextStep: AuthNextSignUpStep(signUpStep: signUpStep),
      userId: "aUserId",
    );
  }

  @override
  Future<SignUpResult> confirmSignUp({
    required String username,
    required String confirmationCode,
    ConfirmSignUpOptions? options,
  }) async {
    _record("confirmSignUp", {"username": username, "confirmationCode": confirmationCode});

    return CognitoSignUpResult(
      isSignUpComplete: signUpStep == AuthSignUpStep.done,
      nextStep: AuthNextSignUpStep(signUpStep: signUpStep),
      userId: "aUserId",
    );
  }

  @override
  Future<ResendSignUpCodeResult> resendSignUpCode({
    required String username,
    ResendSignUpCodeOptions? options,
  }) async {
    _record("resendSignUpCode", {"username": username});

    return const CognitoResendSignUpCodeResult(
      AuthCodeDeliveryDetails(deliveryMedium: DeliveryMedium.email),
    );
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String username,
    ResetPasswordOptions? options,
  }) async {
    _record("resetPassword", {"username": username});

    return const CognitoResetPasswordResult(
      isPasswordReset: false,
      nextStep: ResetPasswordStep(
        updateStep: AuthResetPasswordStep.confirmResetPasswordWithCode,
        codeDeliveryDetails: AuthCodeDeliveryDetails(deliveryMedium: DeliveryMedium.email),
      ),
    );
  }

  @override
  Future<ResetPasswordResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
    ConfirmResetPasswordOptions? options,
  }) async {
    _record("confirmResetPassword", {
      "username": username,
      "newPassword": newPassword,
      "confirmationCode": confirmationCode,
    });

    return const CognitoResetPasswordResult(
      isPasswordReset: true,
      nextStep: ResetPasswordStep(updateStep: AuthResetPasswordStep.done),
    );
  }

  @override
  Future<UpdatePasswordResult> updatePassword({
    required String oldPassword,
    required String newPassword,
    UpdatePasswordOptions? options,
  }) async {
    _record("updatePassword", {"oldPassword": oldPassword, "newPassword": newPassword});

    return const UpdatePasswordResult();
  }

  @override
  Future<AuthSession> fetchAuthSession({FetchAuthSessionOptions? options}) async {
    _record("fetchAuthSession");

    // The tokens of a session are signed by Cognito, so a test answers a session which carries
    // none: what is read from it here is whether the user is signed in.
    return CognitoAuthSession(
      isSignedIn: isSignedIn,
      userPoolTokensResult: const AuthResult.error(_noTokens),
      userSubResult: const AuthResult.error(_noTokens),
      credentialsResult: const AuthResult.error(_noTokens),
      identityIdResult: const AuthResult.error(_noTokens),
    );
  }

  @override
  Future<List<AuthUserAttribute>> fetchUserAttributes({
    FetchUserAttributesOptions? options,
  }) async {
    _record("fetchUserAttributes");

    return attributes;
  }

  @override
  Future<UpdateUserAttributeResult> updateUserAttribute({
    required AuthUserAttributeKey userAttributeKey,
    required String value,
    UpdateUserAttributeOptions? options,
  }) async {
    _record("updateUserAttribute", {"key": userAttributeKey, "value": value});

    return UpdateUserAttributeResult(
      isUpdated: updateAttributeStep == AuthUpdateAttributeStep.done,
      nextStep: AuthNextUpdateAttributeStep(
        updateAttributeStep: updateAttributeStep,
        codeDeliveryDetails: updateAttributeStep == AuthUpdateAttributeStep.done
            ? null
            : const AuthCodeDeliveryDetails(deliveryMedium: DeliveryMedium.email),
      ),
    );
  }

  @override
  Future<ConfirmUserAttributeResult> confirmUserAttribute({
    required AuthUserAttributeKey userAttributeKey,
    required String confirmationCode,
    ConfirmUserAttributeOptions? options,
  }) async {
    _record("confirmUserAttribute", {
      "key": userAttributeKey,
      "confirmationCode": confirmationCode,
    });

    return const ConfirmUserAttributeResult();
  }

  @override
  Future<void> deleteUser() async => _record("deleteUser");

  /// The answer of a cloud which was asked to sign a user in.
  SignInResult _signInResult() => CognitoSignInResult(
    isSignedIn: signInStep == AuthSignInStep.done,
    nextStep: AuthNextSignInStep(signInStep: signInStep),
  );
}
