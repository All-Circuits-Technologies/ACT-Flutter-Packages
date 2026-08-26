// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_amplify_api/act_amplify_api.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// The asset key of the configuration file the tests serve.
const _configKey = "assets/config/default.yaml";

/// The configuration of an application which reaches an API of its own.
const anApiConf = """
amplify:
  api:
    config:
      plugins:
        awsAPIPlugin:
          anApi:
            endpointType: REST
            endpoint: https://an.api/prod
            region: eu-west-3
            authorizationType: NONE
""";

/// The name of one call of a test to the API of the cloud.
typedef ApiCall = ({
  String method,
  String path,
  HttpPayload? body,
  Map<String, String>? headers,
  Map<String, String>? queryParameters,
  String? apiName,
});

/// The configuration of an application which reaches an API of its own.
class FakeApiConfigManager extends AbstractConfigManager with MixinAmplifyApiConfig {
  /// Class constructor
  FakeApiConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeApiConfigManager> withContent(String content) async {
    FakeAssets.serve({_configKey: content});

    final manager = FakeApiConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}

/// The REST API of a cloud, answered by the test.
///
/// It records the calls it was asked for and answers with the response the test gave it, or throws
/// the error the test gave it instead of answering.
class FakeApiPlugin extends APIPluginInterface {
  /// The calls which were asked for, in the order they were asked.
  final List<ApiCall> calls = [];

  /// The response the cloud answers with.
  AWSHttpResponse response = AWSHttpResponse(statusCode: 200, body: utf8.encode("a body"));

  /// The error the cloud throws instead of answering, when the test gave one.
  Exception? error;

  /// Adds the plugin to the API of the cloud, in place of the one of Amplify.
  ///
  /// The categories of Amplify are shared by the whole test file, so the caller has to forget the
  /// plugins of the API once the test is over.
  static Future<FakeApiPlugin> install() async {
    final plugin = FakeApiPlugin();
    await Amplify.API.addPlugin(plugin, authProviderRepo: AmplifyAuthProviderRepository());

    return plugin;
  }

  /// Forgets the calls and the answer of the cloud.
  void forgetCalls() {
    calls.clear();
    response = AWSHttpResponse(statusCode: 200, body: utf8.encode("a body"));
    error = null;
  }

  /// Records the call of [method] on [path] and answers the way the test asked for.
  RestOperation _answer(
    String method,
    String path, {
    HttpPayload? body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) {
    calls.add((
      method: method,
      path: path,
      body: body,
      headers: headers,
      queryParameters: queryParameters,
      apiName: apiName,
    ));

    final error = this.error;
    if (error != null) {
      throw error;
    }

    return RestOperation.fromHttpOperation(
      AWSHttpOperation(
        CancelableOperation.fromFuture(Future.value(response)),
        requestProgress: const Stream.empty(),
        responseProgress: const Stream.empty(),
      ),
    );
  }

  @override
  RestOperation get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) => _answer("get", path, headers: headers, queryParameters: queryParameters, apiName: apiName);

  @override
  RestOperation head(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) => _answer("head", path, headers: headers, queryParameters: queryParameters, apiName: apiName);

  @override
  RestOperation put(
    String path, {
    HttpPayload? body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) => _answer(
    "put",
    path,
    body: body,
    headers: headers,
    queryParameters: queryParameters,
    apiName: apiName,
  );

  @override
  RestOperation post(
    String path, {
    HttpPayload? body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) => _answer(
    "post",
    path,
    body: body,
    headers: headers,
    queryParameters: queryParameters,
    apiName: apiName,
  );

  @override
  RestOperation delete(
    String path, {
    HttpPayload? body,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) => _answer(
    "delete",
    path,
    body: body,
    headers: headers,
    queryParameters: queryParameters,
    apiName: apiName,
  );
}
