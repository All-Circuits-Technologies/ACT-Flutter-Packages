// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// The platform side of the url launcher, answered by the test.
///
/// It records the urls it was asked about and the ones it was asked to open, and it answers what
/// the test decided instead of handing the url to the device.
class FakeUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  /// Whether the platform claims it knows how to open the url it is asked about.
  final bool canLaunchAnswer;

  /// Whether the platform claims it opened the url it was given.
  final bool launchAnswer;

  /// The urls the platform was asked about.
  final List<String> askedUrls = [];

  /// The urls the platform was asked to open.
  final List<String> launchedUrls = [];

  /// Class constructor
  FakeUrlLauncher({this.canLaunchAnswer = true, this.launchAnswer = true});

  /// Installs the fake as the platform the url launcher talks to.
  static FakeUrlLauncher install({bool canLaunchAnswer = true, bool launchAnswer = true}) {
    final launcher = FakeUrlLauncher(canLaunchAnswer: canLaunchAnswer, launchAnswer: launchAnswer);
    UrlLauncherPlatform.instance = launcher;

    return launcher;
  }

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    askedUrls.add(url);

    return canLaunchAnswer;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);

    return launchAnswer;
  }
}
