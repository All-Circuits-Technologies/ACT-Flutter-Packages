// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:io';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Builder to use with derived class in order to create an InternetConnectivityManager with the
/// right type
@protected
abstract class AbstractInternetDerivedBuilder<T extends InternetConnectivityManager>
    extends AbsManagerBuilder<T> {
  /// Class constructor with the class construction
  AbstractInternetDerivedBuilder({
    required ClassFactory<T> factory,
  }) : super(factory);

  /// List of manager dependencies
  @override
  @mustCallSuper
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// Builder for creating the InternetConnectivityManager
class InternetConnectivityBuilder
    extends AbstractInternetDerivedBuilder<InternetConnectivityManager> {
  /// Class constructor
  InternetConnectivityBuilder() : super(factory: InternetConnectivityManager.new);
}

/// Service to check connection to internet
class InternetConnectivityManager extends AbsWithLifeCycle {
  /// This defines a period for retesting internet connection and verify if the internet connection
  /// is constant
  static const _testPeriod = Duration(milliseconds: 300);

  /// This defines the number of time we want to have a stable internet connection "status" when
  /// testing the connection with a period (defined here: [_testPeriod])
  static const _constantValueNb = 3;

  /// This is the default server FQDN to test, in order to verify if we have internet, or not
  static const _defaultServerFqdnToTest = "www.google.com";

  /// This is how we'll allow subscribing to connection changes
  final StreamController<bool> _connectionCtrl;

  /// Lock to wait a check connection result before retrying a new one
  final LockUtility _lockUtility;

  /// The current connection value
  bool _connectionValue;

  /// This is the FQDN to test, in order to know we don't have internet for now
  late final String _serverTestFqdn;

  /// Consent values getter
  bool get hasConnection => _connectionValue;

  /// Consent streams getter
  Stream<bool> get hasInternetStream => _connectionCtrl.stream;

  /// flutter_connectivity
  final Connectivity _connectivity;

  /// Class constructor
  InternetConnectivityManager()
      : _connectionCtrl = StreamController<bool>.broadcast(),
        _connectionValue = true,
        _connectivity = Connectivity(),
        _lockUtility = LockUtility(),
        super();

  /// Init manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _serverTestFqdn = await getTheServerFqdnToTest();

    _connectivity.onConnectivityChanged.listen(_connectionChange);

    await _checkConnection();
  }

  /// Get the server FQDN to test and verify if we are connected to internet
  @protected
  Future<String> getTheServerFqdnToTest() async => _defaultServerFqdnToTest;

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

    appLogger().d("Internet connection is : ${connection ? "up" : "down"}");

    if (_connectionValue != connection) {
      _connectionValue = connection;
      _connectionCtrl.add(connection);
    }

    entity.freeLock();
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

    final resultValues = <bool>[];
    var constantValue = false;

    while (!constantValue) {
      var connection = false;

      var listAddresses = <InternetAddress>[];

      try {
        listAddresses = await InternetAddress.lookup(_serverTestFqdn);
      } catch (error) {
        connection = false;
      }

      if (listAddresses.isNotEmpty && listAddresses[0].rawAddress.isNotEmpty) {
        connection = true;
      }

      resultValues.add(connection);

      if (resultValues.length > _constantValueNb) {
        resultValues.removeAt(0);

        constantValue = true;
        for (final value in resultValues) {
          if (value != connection) {
            constantValue = false;
          }
        }
      }

      if (!constantValue) {
        await Future.delayed(_testPeriod);
      }
    }

    return resultValues.first;
  }

  @override
  Future<void> disposeLifeCycle() async {
    await _connectionCtrl.close();
    await super.disposeLifeCycle();
  }
}
