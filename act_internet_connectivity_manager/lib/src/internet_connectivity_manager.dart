// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/src/mixins/mixin_internet_test_config.dart';
import 'package:act_internet_connectivity_manager/src/platform_deps/internet_test.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Builder to use with derived class in order to create an InternetConnectivityManager with the
/// right type
///
/// This is useful if you want to create another [InternetConnectivityManager] to test the
/// connectivity to a server in addition to test for internet.
///
/// If you don't want to test internet but another server instead, don't use this builder and just
/// use the [MixinInternetTestConfig] mixin for the config manager.
@protected
abstract class AbstractInternetDerivedBuilder<T extends InternetConnectivityManager>
    extends AbsManagerBuilder<T> {
  /// Class constructor with the class construction
  const AbstractInternetDerivedBuilder({
    required ClassFactory<T> factory,
  }) : super(factory);

  /// List of manager dependencies
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// Builder for creating the InternetConnectivityManager
class InternetConnectivityBuilder<C extends MixinInternetTestConfig>
    extends AbstractInternetDerivedBuilder<InternetConnectivityManager> {
  /// Class constructor
  InternetConnectivityBuilder()
      : super(
            factory: () => InternetConnectivityManager(
                  configGetter: globalGetIt().get<C>,
                ));

  /// List of manager dependencies
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [...super.dependsOn(), C];
}

/// Service to check connection to internet
class InternetConnectivityManager extends AbsWithLifeCycle {
  /// This is how we'll allow subscribing to connection changes
  final StreamController<bool> _connectionCtrl;

  /// Lock to wait a check connection result before retrying a new one
  final LockUtility _lockUtility;

  /// The current connection value
  bool _connectionValue;

  /// This is the uri to test, in order to know we don't have internet for now
  late final Uri _serverTestUri;

  /// This is the restartable timer used to restart the connection test, if the periodic
  /// verification has been enabled
  ProgressingRestartableTimer? _restartableTimer;

  /// Consent values getter
  bool get hasConnection => _connectionValue;

  /// Consent streams getter
  Stream<bool> get hasInternetStream => _connectionCtrl.stream;

  /// flutter_connectivity
  final Connectivity _connectivity;

  /// This is the getter of the config manager
  final MixinInternetTestConfig Function() _configGetter;

  /// Class constructor
  InternetConnectivityManager({
    required MixinInternetTestConfig Function() configGetter,
  })  : _connectionCtrl = StreamController<bool>.broadcast(),
        _connectionValue = true,
        _connectivity = Connectivity(),
        _lockUtility = LockUtility(),
        _configGetter = configGetter,
        _restartableTimer = null,
        super();

  /// Init manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _serverTestUri = await getTheServerUriToTest();

    _connectivity.onConnectivityChanged.listen(_connectionChange);

    if (await isPeriodicVerificationEnable()) {
      _restartableTimer = ProgressingRestartableTimer.expFactor(
        await getPeriodicVerificationMinDuration(),
        _checkConnection,
        maxDuration: await getPeriodicVerificationMaxDuration(),
        waitNextRestartToStart: true,
      );
    }

    await _checkConnection();
  }

  /// {@template act_internet_connectivity_manager.InternetConnectivityManager.getTheServerUriToTest}
  /// Get the server Uri to test and verify if we are connected to internet
  /// {@endtemplate}
  @protected
  Future<Uri> getTheServerUriToTest() async => _configGetter().serverUriToTest.load();

  /// {@template act_internet_connectivity_manager.InternetConnectivityManager.getTestPeriod}
  /// Get the period for retesting internet connection and verify if the internet connection
  /// is constant
  /// {@endtemplate}
  @protected
  Future<Duration> getTestPeriod() async => _configGetter().testPeriod.load();

  /// {@template act_internet_connectivity_manager.InternetConnectivityManager.getConstantValueNb}
  /// Get the number of time we want to have a stable internet connection "status" when testing the
  /// connection with a period
  /// {@endtemplate}
  @protected
  Future<int> getConstantValueNb() async => _configGetter().constantValueNb.load();

  /// {@template act_internet_connectivity_manager.InternetConnectivityManager.isPeriodicVerificationEnable}
  /// Returns true if the periodic verification is enabled
  /// {@endtemplate}
  @protected
  Future<bool> isPeriodicVerificationEnable() async =>
      _configGetter().periodicVerificationEnable.load();

  /// {@template act_internet_connectivity_manager.InternetConnectivityManager.getPeriodicVerificationMaxDuration}
  /// Returns the max duration of the periodic verification
  /// {@endtemplate}
  @protected
  Future<Duration> getPeriodicVerificationMaxDuration() async =>
      _configGetter().periodicVerificationMaxDuration.load();

  /// {@template act_internet_connectivity_manager.InternetConnectivityManager.getPeriodicVerificationMinDuration}
  /// Returns the min duration of the periodic verification
  /// {@endtemplate}
  @protected
  Future<Duration> getPeriodicVerificationMinDuration() async =>
      _configGetter().periodicVerificationMinDuration.load();

  /// Called when the connectivity status has changed
  Future<void> _connectionChange(List<ConnectivityResult> result) async {
    await _checkConnection(result);
  }

  /// Check the current connection to internet
  Future<bool> _checkConnection([List<ConnectivityResult>? result]) async {
    if (_lockUtility.isLocked) {
      // In that case, there is already someone which is testing internet, no need to test ourself,
      // we just wait for the result
      await _lockUtility.wait();
      return _connectionValue;
    }

    final entity = await _lockUtility.waitAndLock();

    var connection = false;

    if (result == null || !result.contains(ConnectivityResult.none)) {
      // If the result is none, we know that we loose internet, no need to test if it's true
      connection = await _testInternet();
    }

    if (_connectionValue != connection) {
      appLogger().d("Internet connection is : ${connection ? "up" : "down"}");
      _connectionValue = connection;
      _connectionCtrl.add(connection);
    }

    entity.freeLock();
    _restartableTimer?.restart();
    return connection;
  }

  /// This method tests if the app is connected to internet, but test it several time to be sure
  ///
  /// We need to do that, because [_connectionChange] listener is called as soon as the network has
  /// changed, but the apply to the phone can take more time (for instance: we are informed that
  /// there is no connection but we still have internet for some milliseconds).
  ///
  /// To limit this problem we test internet in a period of a time and wait for a constant result
  Future<bool> _testInternet() async {
    // When an update is detected, it may takes time to detect the network update, that's why we
    // wait for a constant value in order to validate the current state

    final constantValueNb = await getConstantValueNb();
    final testPeriod = await getTestPeriod();

    final resultValues = <bool>[];
    var constantValue = false;

    while (!constantValue) {
      final connection = await InternetTest.requestUriAndTestIfConnectionOk(uri: _serverTestUri);

      resultValues.add(connection);

      if (resultValues.length > constantValueNb) {
        resultValues.removeAt(0);

        constantValue = true;
        for (final value in resultValues) {
          if (value != connection) {
            constantValue = false;
          }
        }
      }

      if (!constantValue) {
        await Future.delayed(testPeriod);
      }
    }

    return resultValues.first;
  }

  @override
  Future<void> disposeLifeCycle() async {
    await _connectionCtrl.close();
    _restartableTimer?.cancel();
    _restartableTimer = null;
    await super.disposeLifeCycle();
  }
}
