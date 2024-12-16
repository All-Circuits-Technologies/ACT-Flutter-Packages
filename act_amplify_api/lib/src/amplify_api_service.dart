// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_amplify_api/src/mixins/mixin_amplify_api_config.dart';
import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the API part of Amplify
class AmplifyApiService<C extends MixinAmplifyApiConfig> extends AbsAmplifyService {
  /// Logs category for the amplify api service
  static const _logsCategory = "api";

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// This contains the list of all the subscriptions done in the service
  final List<StreamSubscription> _apiStreamSubs;

  /// This optional set contains types of all known exceptions which should trigger an event
  /// in [authFailuresStream] stream.
  ///
  /// If null, [authFailuresStream] will not receive any events.
  final Set<Type>? nonTransientAuthFailureTypes;

  /// This is the controller by which authentication failures events are announced.
  ///
  /// See [nonTransientAuthFailureTypes].
  /// Note: we chosen to implement it on API service, not on S3 service, therefore not in common
  /// abstract superclass.
  final StreamController<Exception> _authFailureCtrl;

  /// Subscribe to this stream if you want to receive non-transient authentication failure events.
  ///
  /// Note that this stream requires a not null and not empty [nonTransientAuthFailureTypes].
  ///
  /// You may want to join a sign in page or the like in such case.
  Stream<Exception> get authFailuresStream => _authFailureCtrl.stream;

  /// Class constructor
  AmplifyApiService({
    this.nonTransientAuthFailureTypes,
  })  : _apiStreamSubs = [],
        _authFailureCtrl = StreamController<Exception>.broadcast(),
        super();

  /// Get the list of the linked Amplify plugin needed by the service
  @override
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList() async => [AmplifyAPI()];

  /// Update the amplify config before it's parsed and read by Amplify
  @override
  Future<AmplifyConfig?> updateAmplifyConfig(AmplifyConfig config) async {
    final apiConfig = globalGetIt().get<C>().amplifyApiConfig.load();

    if (apiConfig == null) {
      // Nothing to do
      return config;
    }

    return config.copyWith(api: apiConfig);
  }

  /// Init the api service
  @override
  Future<void> initService({
    LogsHelper? parentLogsHelper,
  }) async {
    _logsHelper = AbsAmplifyService.createLogsHelper(
      logCategory: _logsCategory,
      parentLogsHelper: parentLogsHelper,
    );

    // Listen on Amplify Auth Hub event to get the known information
    _apiStreamSubs.add(Amplify.Hub.listen<ApiHubEventPayload, ApiHubEvent>(
      HubChannel.Api,
      _onApiEvent,
    ));
  }

  /// Request the server by using the HTTP get method
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async =>
      _callHttpMethod(
        Amplify.API.get,
        path,
        headers: headers,
        queryParameters: queryParameters,
        apiName: apiName,
      );

  /// Request the server by using the HTTP head method
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> head(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async =>
      _callHttpMethod(
        Amplify.API.head,
        path,
        headers: headers,
        queryParameters: queryParameters,
        apiName: apiName,
      );

  /// Request the server by using the HTTP put method
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> put(
    String path, {
    Map<String, String>? headers,
    HttpPayload? body,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async =>
      _callHttpMethodWithBody(
        Amplify.API.put,
        path,
        headers: headers,
        body: body,
        queryParameters: queryParameters,
        apiName: apiName,
      );

  /// Request the server by using the HTTP post method
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> post(
    String path, {
    Map<String, String>? headers,
    HttpPayload? body,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async =>
      _callHttpMethodWithBody(
        Amplify.API.post,
        path,
        headers: headers,
        body: body,
        queryParameters: queryParameters,
        apiName: apiName,
      );

  /// Request the server by using the HTTP delete method
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> delete(
    String path, {
    Map<String, String>? headers,
    HttpPayload? body,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async =>
      _callHttpMethodWithBody(
        Amplify.API.delete,
        path,
        headers: headers,
        body: body,
        queryParameters: queryParameters,
        apiName: apiName,
      );

  /// Request the server by using the given [methodToCall], the method to call has no body to send
  /// to the server in its request.
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> _callHttpMethod(
    RestOperation Function(
      String path, {
      Map<String, String>? headers,
      Map<String, String>? queryParameters,
      String? apiName,
    }) methodToCall,
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async =>
      _callHttpMethodWithBody(
        (path, {apiName, body, headers, queryParameters}) => methodToCall(
          path,
          apiName: apiName,
          headers: headers,
          queryParameters: queryParameters,
        ),
        path,
        headers: headers,
        queryParameters: queryParameters,
        apiName: apiName,
      );

  /// Request the server by using the given [methodToCall], the method to call has a body to send
  /// to the server in its request.
  ///
  /// The server URL is defined in the Amplify configuration file, the path given is relative to
  /// this server URL
  Future<AWSHttpResponse?> _callHttpMethodWithBody(
    RestOperation Function(
      String path, {
      Map<String, String>? headers,
      HttpPayload? body,
      Map<String, String>? queryParameters,
      String? apiName,
    }) methodToCall,
    String path, {
    Map<String, String>? headers,
    HttpPayload? body,
    Map<String, String>? queryParameters,
    String? apiName,
  }) async {
    AWSHttpResponse? response;
    try {
      final restOperation = methodToCall(
        path,
        headers: headers,
        body: body,
        queryParameters: queryParameters,
        apiName: apiName,
      );
      response = await restOperation.response;
    } on Exception catch (error) {
      _logsHelper.e("An error occurred with the call of: $path, error: $error");
      _parseException(error);
      if (error is HttpStatusException) {
        response = error.response;
      }
    }

    return response;
  }

  /// React upon few Amplify query exceptions to catch severe authentication issues
  void _parseException(Exception exception) {
    if (nonTransientAuthFailureTypes?.contains(exception.runtimeType) ?? false) {
      _authFailureCtrl.add(exception);
    }
  }

  /// Called when an event occurred in the Amplify API Hub event
  void _onApiEvent(ApiHubEvent event) {
    _logsHelper.d("API Event: $event");
  }

  /// Dispose the service
  @override
  Future<void> dispose() async {
    await super.dispose();

    final futuresList = <Future>[
      _authFailureCtrl.close(),
    ];

    for (final sub in _apiStreamSubs) {
      futuresList.add(sub.cancel());
    }

    await Future.wait(futuresList);
  }
}
