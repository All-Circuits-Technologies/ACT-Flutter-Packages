// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';

/// This class is a utility class which says whether [FlutterAppAuth] has to be allowed to open
/// insecure (plain `http`) connections
sealed class InsecureConnectionsUtility {
  /// Say whether [FlutterAppAuth] has to be allowed to open insecure (plain `http`) connections for
  /// the given [conf].
  ///
  /// It answers true as soon as one of the endpoints the OpenID flow may reach is served over plain
  /// `http`: the [DefaultOAuth2Conf.issuer], the [DefaultOAuth2Conf.discoveryUrl] or one of the
  /// endpoints named one by one (authorization, token or end session). A `https` URL, or a URL
  /// which is absent or unparseable, never triggers it; therefore, a staging or a production realm
  /// stays secure.
  ///
  /// A release build, as [AbsGlobalManager.isReleaseMode] says, always gets false: a realm served
  /// over plain http is a development stack, and a release build never opens a connection in
  /// clear, whatever its configuration names.
  ///
  /// This is what an application asks before wrapping its [FlutterAppAuth] in an
  /// [InsecureDevAppAuth].
  static bool shouldAllowInsecureAppAuthConnections(DefaultOAuth2Conf conf) {
    if (AbsGlobalManager.instance!.isReleaseMode) {
      return false;
    }

    final urlConf = conf.providerUrlConf;

    return _isPlainHttpUrl(conf.issuer) ||
        _isPlainHttpUrl(conf.discoveryUrl) ||
        (urlConf != null &&
            (_isPlainHttpUrl(urlConf.authorizationEndpoint) ||
                _isPlainHttpUrl(urlConf.tokenEndpoint) ||
                _isPlainHttpUrl(urlConf.endSessionEndpoint)));
  }

  /// Say whether [url] is a parseable URL whose scheme is exactly plain `http`, and not `https`
  ///
  /// A null, an empty or a scheme-less [url] is not one.
  static bool _isPlainHttpUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    return Uri.tryParse(url)?.scheme.toLowerCase() == "http";
  }
}
