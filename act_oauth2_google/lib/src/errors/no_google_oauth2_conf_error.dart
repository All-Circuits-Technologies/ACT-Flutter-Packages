class NoGoogleOAuth2ConfError extends Error {
  @override
  String toString() =>
      "No configuration has been found in the conf files for the Google OAut2 provider, or the "
      "conf is incorrect";
}
