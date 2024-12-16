// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This is the authentication status
enum AuthStatus {
  /// An user is signed in the app
  signedIn(isSignedIn: true),

  /// No user is sign in the app
  signedOut,

  /// The user is no more signed in the app and its session has timeout
  sessionExpired,

  /// The user has been deleted and he's no more signed in the app.
  userDeleted;

  /// Say if the current status means that the user is signed in the app
  final bool isSignedIn;

  /// Class constructor
  const AuthStatus({this.isSignedIn = false});
}
