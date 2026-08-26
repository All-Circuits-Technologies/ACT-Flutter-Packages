// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_http_client_manager/src/models/server_urls.dart';
import 'package:act_http_client_manager/src/utilities/url_format_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The URLs of a server which answers on `http://a.server/v1`.
final _serverUrls = ServerUrls(defaultUrl: Uri.parse("http://a.server/v1"), byRelRoute: const {});

/// A request on [relativeRoute], with the parameters a test wants to format the URL from.
RequestParam _request(
  String relativeRoute, {
  Map<String, String>? routeParams,
  Map<String, dynamic>? queryParameters,
}) => RequestParam(
  httpMethod: HttpMethods.get,
  relativeRoute: relativeRoute,
  routeParams: routeParams,
  queryParameters: queryParameters,
);

void main() {
  group("UrlFormatUtility.createServerBaseUrls", () {
    test("builds a https URL for a server which uses SSL", () {
      final url = UrlFormatUtility.createServerBaseUrls(
        const RequesterServerUrlConfig(isUsingSsl: true, hostname: "a.server"),
      );

      expect(url.toString(), "https://a.server");
    });

    test("builds a http URL for a server which does not use SSL", () {
      final url = UrlFormatUtility.createServerBaseUrls(
        const RequesterServerUrlConfig(isUsingSsl: false, hostname: "a.server"),
      );

      expect(url.toString(), "http://a.server");
    });

    test("adds the port of the server when it has one", () {
      final url = UrlFormatUtility.createServerBaseUrls(
        const RequesterServerUrlConfig(isUsingSsl: false, hostname: "a.server", port: 8080),
      );

      expect(url.toString(), "http://a.server:8080");
    });

    test("adds the base path which is shared by every route of the server", () {
      final url = UrlFormatUtility.createServerBaseUrls(
        const RequesterServerUrlConfig(isUsingSsl: false, hostname: "a.server", baseUrl: "v1"),
      );

      expect(url.toString(), "http://a.server/v1");
    });

    test("adds a base path which is written with a leading separator", () {
      final url = UrlFormatUtility.createServerBaseUrls(
        const RequesterServerUrlConfig(isUsingSsl: false, hostname: "a.server", baseUrl: "/v1"),
      );

      expect(url.toString(), "http://a.server/v1");
    });
  });

  group("UrlFormatUtility.formatFullUrl", () {
    test("appends the route of the request to the base of the server", () {
      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("items"),
        serverUrls: _serverUrls,
      );

      expect(url.toString(), "http://a.server/v1/items");
    });

    test("drops the empty parts of a route which is written with separators around it", () {
      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("/items//list/"),
        serverUrls: _serverUrls,
      );

      expect(url.toString(), "http://a.server/v1/items/list");
    });

    test("replaces in the route what the parameters of the route name", () {
      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("items/{id}/tags", routeParams: {"{id}": "7"}),
        serverUrls: _serverUrls,
      );

      expect(url.toString(), "http://a.server/v1/items/7/tags");
    });

    test("adds the query parameters of the request", () {
      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("items", queryParameters: {"page": "2", "size": "10"}),
        serverUrls: _serverUrls,
      );

      expect(url.toString(), "http://a.server/v1/items?page=2&size=10");
    });

    test("takes the base of the server which answers on the route of the request", () {
      final serverUrls = ServerUrls(
        defaultUrl: Uri.parse("http://a.server/v1"),
        byRelRoute: {"items": Uri.parse("https://another.server:8443/api")},
      );

      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("items"),
        serverUrls: serverUrls,
      );

      expect(url.toString(), "https://another.server:8443/api/items");
    });

    test("names the server of a route as it is written, parameters included", () {
      final serverUrls = ServerUrls(
        defaultUrl: Uri.parse("http://a.server/v1"),
        byRelRoute: {"items/{id}": Uri.parse("https://another.server/api")},
      );

      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("items/{id}", routeParams: {"{id}": "7"}),
        serverUrls: serverUrls,
      );

      expect(url.toString(), "https://another.server/api/items/7");
    });

    test("takes the default base of the server for a route no other server answers on", () {
      final serverUrls = ServerUrls(
        defaultUrl: Uri.parse("http://a.server/v1"),
        byRelRoute: {"items": Uri.parse("https://another.server/api")},
      );

      final url = UrlFormatUtility.formatFullUrl(
        requestParam: _request("tags"),
        serverUrls: serverUrls,
      );

      expect(url.toString(), "http://a.server/v1/tags");
    });
  });
}
