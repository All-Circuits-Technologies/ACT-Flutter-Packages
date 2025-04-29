import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_core/src/models/oauth2_tokens.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

mixin MixinDefaultOAuth2Provider on AbsOAuth2ProviderService {
  static const redirectUrlSeparator = ":/";
  static const redirectUrlSuffix = "${redirectUrlSeparator}oauthredirect";

  late final DefaultOAuth2Conf _conf;

  late final MixinOAuth2TokensSecret _secretService;

  OAuth2Tokens _oAuth2Tokens = OAuth2Tokens.init();

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _conf = await getDefaultOAuth2Conf();
    _secretService = await getTokensSecretService();
    final tokensInMemory = await _secretService.oauth2Tokens.load();
    if (tokensInMemory != null) {
      _oAuth2Tokens = tokensInMemory;
    }
  }

  @protected
  Future<MixinOAuth2TokensSecret> getTokensSecretService();

  @override
  Future<bool> isUserSigned() async {
    final isUserSigned =
        (_oAuth2Tokens.accessToken?.isValid ?? false) ||
        (_oAuth2Tokens.refreshToken?.isValid ?? false);
    if (!isUserSigned) {
      // If the token and the refresh token are expired, we consider that we are signed out
      setAuthStatus(AuthStatus.signedOut);
    }

    return isUserSigned;
  }

  @override
  Future<AuthTokens?> getTokens() async {
    if (_oAuth2Tokens.accessToken?.isValid ?? false) {
      return _oAuth2Tokens.accessToken!.token;
    }

    if (_oAuth2Tokens.refreshToken == null || !_oAuth2Tokens.refreshToken!.isValid) {
      // If the refresh token is expired, we consider that we are signed out
      setAuthStatus(AuthStatus.signedOut);
      return null;
    }

    final redirectUrl = await buildRedirectUrl();
    TokenResponse? response;
    try {
      response = await appAuth.token(
        TokenRequest(
          _conf.clientId,
          redirectUrl,
          issuer: _conf.issuer,
          discoveryUrl: _conf.discoveryUrl,
          serviceConfiguration: _conf.providerUrlConf?.toServiceConf(),
          refreshToken: _oAuth2Tokens.refreshToken!.token,
          scopes: _conf.scopes,
        ),
      );
    } catch (error) {
      logsHelper.e("An error occurred when tried to get a token from the refresh token: $error");
    }

    if (response == null) {
      // We don't consider that we are signed out here, because if we have lost internet, this
      // request will fail even if the refresh token is still valid
      return null;
    }

    if (!await _parseTokenResponse(response)) {
      return null;
    }

    return _oAuth2Tokens.accessToken?.token;
  }

  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) async {
    final redirectUrl = await buildRedirectUrl();
    AuthSignInStatus? errorStatus;
    AuthorizationTokenResponse? response;
    try {
      response = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _conf.clientId,
          redirectUrl,
          issuer: _conf.issuer,
          discoveryUrl: _conf.discoveryUrl,
          serviceConfiguration: _conf.providerUrlConf?.toServiceConf(),
          scopes: _conf.scopes,
        ),
      );
    } on FlutterAppAuthUserCancelledException catch (error) {
      // Handle user cancellation
      errorStatus = AuthSignInStatus.sessionExpired;
      logsHelper.i("User has cancelled the OAuth2 authentication");
    } catch (error) {
      errorStatus = AuthSignInStatus.genericError;
      logsHelper.e("An error occurred when tried to sign in the user: $error");
    }

    if (errorStatus != null) {
      return AuthSignInResult(status: errorStatus);
    }

    if (!await _parseTokenResponse(response!)) {
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    setAuthStatus(AuthStatus.signedIn);
    return AuthSignInResult(status: AuthSignInStatus.done, extra: _oAuth2Tokens.accessToken?.token);
  }

  @override
  Future<bool> signOut() async {
    final redirectUrl = await buildPostLogoutRedirectUrl();
    var result = false;
    try {
      await appAuth.endSession(
        EndSessionRequest(
          idTokenHint: _oAuth2Tokens.idToken,
          postLogoutRedirectUrl: redirectUrl,
          issuer: _conf.issuer,
          discoveryUrl: _conf.discoveryUrl,
          serviceConfiguration: _conf.providerUrlConf?.toServiceConf(),
        ),
      );
      result = true;
    } catch (error) {
      logsHelper.e("An error occurred when tried to sign out the user");
    }

    if (!result) {
      return false;
    }

    // Clean the auth info
    await _setOAuthTokens(_oAuth2Tokens.copyAndClear());

    setAuthStatus(AuthStatus.signedOut);

    return true;
  }

  @protected
  Future<String> buildRedirectUrl() async => "${_conf.appAuthRedirectScheme}$redirectUrlSuffix";

  @protected
  Future<String> buildPostLogoutRedirectUrl() async =>
      "${_conf.appAuthRedirectScheme}$redirectUrlSeparator";

  Future<bool> _parseTokenResponse(TokenResponse response) async {
    final parseResult = _oAuth2Tokens.parseTokenResponseAndCopy(
      response: response,
      logsHelper: logsHelper,
    );
    await _setOAuthTokens(parseResult.newValue);

    return parseResult.isOk;
  }

  Future<void> _setOAuthTokens(OAuth2Tokens newTokens) async {
    _oAuth2Tokens = newTokens;
    await _secretService.oauth2Tokens.store(newTokens);
  }
}
