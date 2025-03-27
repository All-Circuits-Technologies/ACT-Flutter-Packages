// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:url_launcher/url_launcher.dart';

/// Contains useful methods to launch url
sealed class UrlLauncherUtility {
  /// Open the given URL in the app browser
  ///
  /// Returns false if the URI can't be open (for instance, if you haven't added the needed info
  /// in the Android manifest or Info.plist
  static Future<bool> openUrlInBrowser(Uri uri) async {
    if (!(await canLaunchUrl(uri))) {
      appLogger().w("We can't launch the url: ${uri.path}");
      return false;
    }

    return launchUrl(uri);
  }
}
