// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_manager/act_server_req_manager.dart';
import 'package:act_server_req_manager/src/models/server_urls.dart';

/// Contains useful methods to format and cast the [Uri] from server urls
sealed class UrlFormatUtility {
  /// The separator to use with URL path
  static const urlPathSeparator = "/";

  /// Format the full URL thanks the [RequestParam] and [ServerUrls] given
  static Uri formatFullUrl({
    required RequestParam requestParam,
    required ServerUrls serverUrls,
  }) {
    var relRoutePath = requestParam.relativeRoute;
    final urlBase = serverUrls.byRelRoute[relRoutePath] ?? serverUrls.defaultUrl;

    if (requestParam.routeParams != null) {
      for (final param in requestParam.routeParams!.entries) {
        relRoutePath = relRoutePath.replaceAll(param.key, param.value);
      }
    }

    final pathSegments = List<String>.from(urlBase.pathSegments);
    pathSegments.addAll(relRoutePath.split(urlPathSeparator));

    // We remove the empty parts
    pathSegments.removeWhere((element) => element.isEmpty);

    return urlBase.replace(
      pathSegments: pathSegments,
      queryParameters: requestParam.queryParameters,
    );
  }

  /// Create an URI from the given [RequesterServerUrlConfig] config, the URI only contains the
  /// base of the URI and not the relative path
  static Uri createServerBaseUrls(RequesterServerUrlConfig config) {
    String? basePathCleaned;

    if (config.baseUrl != null &&
        config.baseUrl!.isNotEmpty &&
        config.baseUrl![0] == urlPathSeparator) {
      basePathCleaned = config.baseUrl!.substring(1);
    } else {
      basePathCleaned = config.baseUrl;
    }

    return Uri(
      scheme: config.isUsingSsl ? ServerReqConstants.httpsScheme : ServerReqConstants.httpScheme,
      host: config.hostname,
      port: config.port,
      path: basePathCleaned,
    );
  }
}
