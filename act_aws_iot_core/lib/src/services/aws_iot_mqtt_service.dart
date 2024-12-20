// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_aws_iot_core/src/aws_iot_mqtt_sub_watcher.dart';
import 'package:act_aws_iot_core/src/models/aws_iot_mqtt_config_model.dart';
import 'package:act_aws_iot_core/src/services/abs_aws_iot_service.dart';
import 'package:act_aws_iot_core/src/services/aws_iot_mqtt_subscription_service.dart';
import 'package:act_aws_iot_core/src/types/aws_iot_mqtt_sub_event.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:aws_common/aws_common.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mutex/mutex.dart';

/// This service handles the connection to the AWS IoT MQTT server.
/// It uses the [MqttServerClient] from the mqtt_client package to connect to the server.
/// Its goal is to stay connected to the server when conditions are met: internet connection is
/// available and the user is authenticated. [_observerUtilities] are used to monitor these
/// conditions.
///
/// The service will inform other services when its connection changes by publishing it's
/// connection status on the AwsIotMqttService.connectionStatus stream.
/// It will also publish the topics that were subscribed to, unsubscribed from and the messages
/// received on the corresponding streams: AwsIotMqttService.onSubEventStream,
/// AwsIotMqttService.onUnsubscribedStream, [AwsIotMqttService.onMessageReceivedStream].
class AwsIotMqttService<AuthManager extends AbsAuthManager,
    AmplifyManager extends AbsAmplifyManager> extends AbsAwsIotService {
  static const _awsIotService = AWSService('iotdevicegateway');

  /// This is the base period for the reconnect timer.
  static const _reconnectTimerBasePeriod = Duration(seconds: 1);

  /// This is the maximum period for the reconnect timer.
  static const _reconnectTimerMaxPeriod = Duration(minutes: 5);

  /// QoS level for the mqtt messages. Aws doesn't support QoS 2 and QoS 0 is not reliable.
  static const _qosLevel = MqttQos.atLeastOnce;

  /// Log category for the mqtt service
  static const _logCategory = 'mqtt';

  /// The URL path for MQTT connections.
  static const _urlPath = '/mqtt';

  /// The scheme used for MQTT connections, indicating a secure WebSocket connection.
  static const _scheme = 'wss';

  /// The minimum delay between two connection attempts.
  static const _minConnectPeriod = Duration(seconds: 30);

  /// The configuration to use for the service
  final AwsIotMqttConfigModel config;

  /// When this is true we will try to reconnect to the mqtt server if the connection is lost
  /// abrutly. Check the [_onDisconnected] method and [_isDisconnectingFlag] attribut to understand
  /// how the reason of the disconnection is determined.
  final bool _autoReconnect;

  /// Mutex to protect the [_mqttClient]. Any operation on the mqtt client should be
  /// protected by this mutex.
  final Mutex _mqttClientMutex;

  /// List of observer utilities to listen to.
  ///
  /// The validity of each oberser is checked in the [_unsafeConnect] method before trying to
  /// connect to the mqtt server.
  /// Each observer utility is listened to and the [_onObserverValidityChanged] method is called
  /// when a new value is emitted. This method will then call the [_connect] or [_disconnect] method
  /// depending on the validity of the observer utility.
  final List<StreamObserver> _observerUtilities;

  /// Subscriptions associated with the [_observerUtilities]
  final List<StreamSubscription> _observerSubscriptions;

  /// [StreamController] to publish the connection status of the mqtt service.
  final StreamController<bool> _connectionStatusController;

  /// [StreamController] to publish the topics that were subscribed to by the mqtt service.
  final StreamController<({String topic, AwsIotMqttSubEvent evt})> _onSubEventController;

  /// [StreamController] to publish the messages received by the mqtt service.
  final StreamController<({String topic, String msg})> _onMessageReceivedController;

  /// Timer that is used to restart the connexion when it failed despite all observers being valid.
  ///
  /// This can append for example if the server is down. In such case we would fail to connect but
  /// we would retry after a certain amount of time.
  late final ProgressingRestartableTimer _reconnectTimer;

  /// This is the service responsible for the management of the subscription to the mqtt topics.
  late final AwsIotMqttSubcriptionService _mqttSubcriptionService;

  /// This flag is used by the mechanism that prevents the service from trying to connect too
  /// frequently. It is set to false when a connection is requested and will remain false for the
  /// [_minConnectPeriod] duration. If a connection is requested during this period, the flag will
  /// be set to true and the connection will be attempted after the [_minConnectPeriod] duration.
  /// Finally, the flag is null when no connection was attempted to recently, meaning that we can
  /// try to connect to the mqtt server without any delay.
  bool? _isConnectAfterDelayEnabled;

  /// Flag to indicate if a disconnection was requested. It is checked in the [_onDisconnected]
  /// method to know whether the disconnection was requested or not (like when we lose the
  /// connection for example).
  /// The flag is raised in the [_unsafeDisconnect] method and lowered in the [_onDisconnected]
  /// method.
  bool _isDisconnectingFlag;

  /// The mqtt client
  ///
  /// If this is null, then we are not connected to the mqtt server.
  MqttServerClient? _mqttClient;

  /// [StreamSubscription] associated with the mqtt client updates.
  StreamSubscription? _mqttClientUpdatesSubscription;

  /// [Stream] to listen to the connection status of the mqtt service.
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// [Stream] to listen to the topics that were subscribed to by the mqtt service.
  Stream<({String topic, AwsIotMqttSubEvent evt})> get onSubEventStream =>
      _onSubEventController.stream;

  /// [Stream] to listen to the messages received by the mqtt service.
  Stream<({String topic, String msg})> get onMessageReceivedStream =>
      _onMessageReceivedController.stream;

  /// Class constructor
  AwsIotMqttService({
    required LogsHelper iotManagerLogsHelper,
    required this.config,
    List<StreamObserver> extraStreamObservers = const [],
    bool autoReconnect = true,
  })  : _observerSubscriptions = <StreamSubscription>[],
        _observerUtilities = [
          InternetStreamObserver(),
          AuthStreamObserver<AuthManager>(),
          ...extraStreamObservers,
        ],
        _autoReconnect = autoReconnect,
        _connectionStatusController = StreamController.broadcast(),
        _onSubEventController = StreamController.broadcast(),
        _onMessageReceivedController = StreamController.broadcast(),
        _mqttClientMutex = Mutex(),
        _isDisconnectingFlag = false,
        super(
          logsCategory: _logCategory,
          iotManagerLogsHelper: iotManagerLogsHelper,
        ) {
    // Create the reconnect timer. We can't create it before because it needs to call the _connect
    // method which is not available before the object is fully created.
    _reconnectTimer = ProgressingRestartableTimer.expFactor(
      _reconnectTimerBasePeriod,
      _connect,
      maxDuration: _reconnectTimerMaxPeriod,
      waitNextRestartToStart: true,
    );
    // Create the mqtt subscription service
    _mqttSubcriptionService = AwsIotMqttSubcriptionService(
      mqttService: this,
      iotManagerLogsHelper: iotManagerLogsHelper,
    );
  }

  /// Initialize the mqtt service
  ///
  /// Listen to the observer utilities and try to connect to the mqtt server.
  @override
  Future<void> initService() async {
    await _mqttSubcriptionService.initService();

    // Listen to the observer utilities
    for (final obs in _observerUtilities) {
      _subToStreamObserver(obs);
    }

    // Try to connect to the mqtt server. Since the connect method might take some time, we don't
    // await it here.
    unawaited(_connect());
  }

  /// Add a stream observer to the [_observerUtilities]
  void addStreamObserver(StreamObserver observer) {
    _observerUtilities.add(observer);
    _subToStreamObserver(observer);
  }

  /// The method subscribes to the [observer]
  void _subToStreamObserver(StreamObserver observer) {
    final obsSub = observer.stream.listen(_onObserverValidityChanged);
    _observerSubscriptions.add(obsSub);
  }

  /// Ask the server to subscribe to a topic
  ///
  /// Returns false if the mqtt client is not connected to the server or if we failed to request
  /// the server.
  /// Returns true if the subscription request was sent to the server. Make sure to listen to the
  /// [onSubEventStream] to know if the subscription was successful or not.
  bool subscribe(String topic) {
    if (_mqttClient == null) {
      return false;
    }

    return _mqttClient!.subscribe(topic, _qosLevel) != null;
  }

  /// Ask the server to unsubscribe from a topic
  ///
  /// Returns false if the mqtt client is not connected to the server.
  /// Returns true if the unsubscription request was sent to the server. Make sure to listen to the
  /// [onSubEventStream] to know if the unsubscription was successful.
  bool unsubscribe(String topic) {
    if (_mqttClient == null) {
      return false;
    }

    _mqttClient!.unsubscribe(topic);
    return true;
  }

  /// Get a [AwsIotMqttSubWatcher] for the given topic.
  AwsIotMqttSubWatcher getSubscriptionWatcher(String topic) =>
      _mqttSubcriptionService.getWatcher(topic);

  /// Protected version of [_unsafePublish]
  Future<bool> publish(
    String topic,
    String payload,
  ) async =>
      _mqttClientMutex.protect(() => _unsafePublish(topic, payload));

  /// Publish a message to a topic with the given payload
  Future<bool> _unsafePublish(
    String topic,
    String payload,
  ) async {
    if (_mqttClient == null) {
      logsHelper.d('Failed to publish. Not connected to server');
      return false;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    // Publish the message to the mqtt server
    try {
      _mqttClient!.publishMessage(topic, _qosLevel, builder.payload!);
    } catch (e) {
      logsHelper.e('Failed to publish with Exception: $e');
      return false;
    }

    return true;
  }

  /// Handle the validity change of an observer utility
  Future<void> _onObserverValidityChanged(bool isValid) async {
    if (isValid) {
      await _connect();
    } else {
      await _disconnect();
    }
  }

  /// Connect to the mqtt server
  Future<bool> _unsafeConnect() async {
    // Check if we are already connected to the mqtt server
    if (_mqttClient != null) {
      logsHelper.i('Connection attempt canceled, already connected to the mqtt server');
      return true;
    }

    // Check the observer utilities
    for (final observerUtility in _observerUtilities) {
      if (!observerUtility.isValid) {
        logsHelper.e('Observer utility ${observerUtility.runtimeType} is not valid');
        return false;
      }
    }

    // Get a new connected mqtt client
    final newClient = await _getNewConnectedMqttClient();
    if (newClient == null) {
      logsHelper.e('Failed to get a new mqtt client');
      _reconnectTimer.restart();
      return false;
    }

    // Connected! Save the mqtt client and listen to the messages
    _mqttClient = newClient;
    _mqttClientUpdatesSubscription = _mqttClient!.updates!.listen(_onMessageReceived);

    // Notify that we are connected
    await _onConnected();

    return true;
  }

  /// This method will create a new mqtt client and try to connect to the mqtt server.
  ///
  /// Null will be returned if we failed to get the credentials or the identity id.
  /// Null will also be returned if the connection was refused by the server.
  /// THIS METHOD IS ONLY MEANT TO BE USED IN THE [_unsafeConnect] METHOD.
  Future<MqttServerClient?> _getNewConnectedMqttClient() async {
    final cognitoService = config.cognitoService;

    // Get the credentials to setup the mqtt client
    final authSession = await cognitoService.getAwsAuthSession();

    // Get the credentials. It will be used to sign the mqtt connection
    final creds = authSession.credentialsResult.valueOrNull;
    if (creds == null) {
      logsHelper.e('No credentials found in the auth session, retrying');
      return null;
    }

    // Get the identity id. It will be used as clientName for the mqtt connection
    final identityId = authSession.identityIdResult.valueOrNull;
    if (identityId == null) {
      logsHelper.e('No identity id found in the auth session, retrying');
      return null;
    }

    final url = cognitoService
        .signUrl(
          creds: creds,
          service: _awsIotService,
          region: config.region,
          endpoint: config.endpoint,
          signerValidityDuration: config.signerValidityDuration,
          urlPath: _urlPath,
          scheme: _scheme,
        )
        .toString();

    final newClient = _createMqttClient(url, identityId);

    logsHelper.d('Connecting to the mqtt server as client id $identityId');

    MqttClientConnectionStatus? mqttStatus;

    try {
      mqttStatus = await newClient.connect();
    } catch (e) {
      logsHelper.e(e);
      return null;
    }

    if (mqttStatus?.returnCode != MqttConnectReturnCode.connectionAccepted) {
      logsHelper.e(
        'Connection refused with return code ${mqttStatus?.returnCode}',
      );
      return null;
    }

    return newClient;
  }

  /// Protected call to [_unsafeConnect]
  Future<bool> _connect() => _mqttClientMutex.protect(_unsafeConnect);

  /// Disconnect from the mqtt server
  Future<bool> _unsafeDisconnect() async {
    // Check if we are already disconnected from the mqtt server
    if (_mqttClient == null) {
      logsHelper.i('Already disconnected from the mqtt server');
      return true;
    }

    logsHelper.d('Disconnecting from the mqtt server');
    // Mark that we are disconnecting so we don't try to reconnect
    _isDisconnectingFlag = true;
    // We reset the timer in that case, because we explicitly choose to disconnect from MQTT client.
    _reconnectTimer.reset();

    try {
      _mqttClient!.disconnect();
    } catch (e) {
      logsHelper.e('Failed to disconnect with Exception: $e');
      _isDisconnectingFlag = false;
      return false;
    }

    return true;
  }

  /// Protected method to disconnect from the mqtt server
  Future<bool> _disconnect() => _mqttClientMutex.protect(_unsafeDisconnect);

  /// Handle the mqtt client connection event
  Future<void> _onConnected() async {
    logsHelper.d('Connected to the mqtt server');
    _connectionStatusController.add(true);
  }

  /// Handle the mqtt client disconnection event
  Future<void> _onDisconnected() => _mqttClientMutex.protect(
        () async {
          await _mqttClientUpdatesSubscription?.cancel();
          _mqttClient = null;

          // Notify that we are disconnected
          _connectionStatusController.add(false);

          // If a disconnection was requested, we should not try to reconnect
          if (_isDisconnectingFlag) {
            _isDisconnectingFlag = false;
            logsHelper.d('Successfully disconnected from the mqtt server');
            return;
          }

          // If the connection was lost abrutly and if we are allowed to auto reconnect, then we
          // should try to reconnect to the mqtt server.
          if (_autoReconnect) {
            final isAllSubscribed = await _mqttSubcriptionService.isAllSubscribed();
            if (isAllSubscribed) {
              // If we were subscribed to all the topics, this means that the connection has
              // correctly succeeded; therefore we can reset the restartableTimer
              _reconnectTimer.reset();
            }

            logsHelper.d(
              'Connection lost abruptly. Auto reconnect is enabled, trying to reconnect...',
            );
            _reconnectTimer.restart();
          }
        },
      );

  /// Handle the mqtt client failed connection event
  void _onFailedConnectionAttempt(int attemptNumber) {
    logsHelper.e('Failed to connect to the mqtt server. Attempt number $attemptNumber');
  }

  /// Forward the mqtt client subscription event on the [onSubEventStream]
  void _onSubscribed(String topic) {
    _onSubEventController.add((
      topic: topic,
      evt: AwsIotMqttSubEvent.subscribed,
    ));
  }

  /// Handle the mqtt client topic subscription failed event
  void _onSubscribeFailed(String topic) {
    _onSubEventController.add((
      topic: topic,
      evt: AwsIotMqttSubEvent.subscriptionFailed,
    ));
  }

  /// Handle the mqtt client onUnsubscribed event
  void _onUnsubscribed(String? topic) {
    if (topic == null) {
      // How tf would this happen?
      return;
    }

    _onSubEventController.add((
      topic: topic,
      evt: AwsIotMqttSubEvent.unsubscribed,
    ));
  }

  /// Handle the mqtt client message received event
  void _onMessageReceived(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      // Extract the topic and the payload from the message
      final topic = message.topic;
      final payload = message.payload as MqttPublishMessage;
      final payloadStr = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
      // Forward the message to the listeners
      _onMessageReceivedController.add((topic: topic, msg: payloadStr));
    }
  }

  /// Create an mqtt client with the given url and client id
  MqttServerClient _createMqttClient(String url, String clientId) {
    // Create the mqtt client
    final client = MqttServerClient.withPort(
      url,
      clientId,
      config.mqttPort,
    );

    // Configure the mqtt client
    client.setProtocolV311(); // Required by AWS IoT
    client.logging(on: false); // Disable logging
    client.useWebSocket = true; // Use websockets, no choice when using Amplify to authenticate
    client.secure = false; // Secure connection is handled by Amplify
    client.autoReconnect = false; // No auto reconnect, we handle it ourselves
    client.disconnectOnNoResponsePeriod = 45;
    client.keepAlivePeriod = 30;

    // Set the clientId as conneection message since it is required by AWS IoT
    final connMess = MqttConnectMessage().withClientIdentifier(clientId);
    client.connectionMessage = connMess;

    // Set the callbacks
    client.onDisconnected = _onDisconnected;
    client.onFailedConnectionAttempt = _onFailedConnectionAttempt;
    client.onSubscribed = _onSubscribed;
    client.onSubscribeFail = _onSubscribeFailed;
    client.onUnsubscribed = _onUnsubscribed;
    // client.onConnected = X; // Not used, we do it ourselves in the _unsafeConnect method

    // Return the mqtt client
    return client;
  }

  /// Dispose the mqtt service:
  /// - Cancel the observer subscriptions
  /// - Cancel the reconnect timer
  /// - Disconnect from the mqtt server
  /// - Close all our streams
  @override
  Future<void> dispose() async {
    // Cancel the observer subscriptions
    for (final sub in _observerSubscriptions) {
      await sub.cancel();
    }

    // Cancel the reconnect timer
    _reconnectTimer.cancel();

    // Disconnect from the mqtt server
    await _disconnect();
    await _mqttClientUpdatesSubscription?.cancel();

    // Close all the streams
    await _connectionStatusController.close();
    await _onSubEventController.close();
    await _onMessageReceivedController.close();

    // Dispose the mqtt subscription service
    await _mqttSubcriptionService.dispose();

    await super.dispose();
  }
}
