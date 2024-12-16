// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle_manager/act_life_cycle_manager.dart';
import 'package:act_location_manager/act_location_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:location/location.dart';

/// Builder for creating the WiFiManager
class WiFiBuilder extends ManagerBuilder<WiFiManager> {
  /// Class constructor with the class construction
  WiFiBuilder() : super(() => WiFiManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [
        LoggerManager,
        LocationManager,
        LifeCycleManager,
      ];
}

/// The WiFi manager allows to manage the WiFi features of the mobile
class WiFiManager extends AbstractManager {
  /// The [Connectivity] class is from a flutter library and it's a trustful
  /// lib. We get WiFi info from it, but unfortunately this lib can't connect to
  /// WiFi.
  final Connectivity _connectivity;
  _ObserveLowLevelChanging _observeConnection;

  WiFiManager()
      : _connectivity = Connectivity(),
        super();

  @override
  Future<void> initManager() {
    _observeConnection = _ObserveLowLevelChanging(this);
    return null;
  }

  @override
  Future<void> dispose() async {
    return _observeConnection.dispose();
  }

  /// From Android SDK 26, we need to have the precise location permission to
  /// get the WiFi current SSID from the mobile. This method manages the
  /// particular permission for specific version
  Future<bool> _manageLocationIfNeeded() async {
    // From android 8.0 onwards the GPS must be ON (high accuracy) in order to
    // be able to obtain the SSID.
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 26) {
        if (!await GlobalGetIt().get<LocationManager>().startLocation()) {
          AppLogger().w("A problem occurred when trying to start the GPS "
              "in order to get the WiFi SSID");
          return false;
        }
      }
    } else {
      LocationAuthorizationStatus locationStatus =
          await _connectivity.getLocationServiceAuthorization();

      if (locationStatus == LocationAuthorizationStatus.authorizedAlways ||
          locationStatus == LocationAuthorizationStatus.authorizedWhenInUse) {
        return true;
      }

      locationStatus =
          await _connectivity.requestLocationServiceAuthorization();

      if (locationStatus != LocationAuthorizationStatus.authorizedAlways &&
          locationStatus != LocationAuthorizationStatus.authorizedWhenInUse) {
        return false;
      }
    }

    return true;
  }

  /// This method tests if the location permission will be requested if we
  /// call the getWiFiName method
  Future<bool> get willItAskedForLocationPermission async {
    // From android 8.0 onwards the GPS must be ON (high accuracy) in order to
    // be able to obtain the SSID.
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 26) {
        var userPerm = await GlobalGetIt().get<LocationManager>().hasPermission;
        return (userPerm != PermissionStatus.granted);
      }
    } else {
      LocationAuthorizationStatus locationStatus =
          await _connectivity.getLocationServiceAuthorization();

      if (locationStatus != LocationAuthorizationStatus.authorizedAlways &&
          locationStatus != LocationAuthorizationStatus.authorizedWhenInUse) {
        return true;
      }
    }

    return false;
  }

  /// Get the current WiFi SSID or null if we haven't the right permissions or
  /// if we aren't connected to a WiFi network
  Future<String> getWiFiSsid() async {
    if (!await _manageLocationIfNeeded()) {
      return null;
    }

    return _connectivity.getWifiName();
  }

  /// Generate a [WiFiObserveSsid] class instance, this allows to observe the
  /// modification of WiFi (if we are connected to a WiFi or if we change of
  /// WiFi)
  WiFiObserveSsid generateAWiFiObserver() =>
      _observeConnection._ssidObserver.generateObserver();

  /// Get the current WiFi BSSID or null if we haven't the right permissions or
  /// if we aren't connected to a WiFi network
  Future<String> getWiFiBssid() async {
    if (!await _manageLocationIfNeeded()) {
      return null;
    }

    return _connectivity.getWifiBSSID();
  }

  /// Get the current WiFi Ip or null if we haven't the right permissions or
  /// if we aren't connected to a WiFi network
  Future<String> getWiFiIp() async => _connectivity.getWifiIP();
}

/// This observes the low level changing and tell if it's necessary to refresh
/// the WiFi info
///
/// This is useful to manage cases where you don't have information about WiFi
/// for instance when the app is in background
class _ObserveLowLevelChanging {
  final _SsidWiFiObserverManager _ssidObserver;

  StreamController<bool> _refreshWiFiData;
  StreamSubscription<ConnectivityResult> _connectivitySub;
  StreamSubscription<AppLifecycleState> _lifeCycleSub;
  ConnectivityResult _connectivityResult;

  /// Emit true when we are connected to a new WiFi
  /// Emit false when we are no more connected to WiFi
  /// Emit null when the state has been changed but we don't know if we are
  ///   connected to a WiFi or not
  Stream<bool> get needToRefreshWifiInfoStream => _refreshWiFiData.stream;

  _ObserveLowLevelChanging(WiFiManager wiFiManager)
      : _ssidObserver = _SsidWiFiObserverManager(wiFiManager) {
    _refreshWiFiData = StreamController.broadcast();
    _connectivitySub = wiFiManager._connectivity.onConnectivityChanged
        .listen(_onConnectivityUpdate);
    _lifeCycleSub = GlobalGetIt()
        .get<LifeCycleManager>()
        .lifeCycleStream
        .listen(_onLifeCycleStateUpdate);
  }

  Future<void> dispose() async {
    return Future.wait([
      _connectivitySub.cancel(),
      _lifeCycleSub.cancel(),
      _refreshWiFiData.close(),
    ]);
  }

  /// Called when the connectivity type has changed
  void _onConnectivityUpdate(ConnectivityResult result) {
    if (result == ConnectivityResult.wifi ||
        _connectivityResult == ConnectivityResult.wifi) {
      _refreshWiFiData.add(result == ConnectivityResult.wifi);
    }

    _connectivityResult = result;
  }

  /// Called when the life cycle state of the app has been updated
  void _onLifeCycleStateUpdate(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // From doc:
      // // Note that connectivity changes are no longer communicated to Android
      // // apps in the background starting with Android O. You should always
      // // check for connectivity status when your app is resumed. The
      // // broadcast is only useful when your application is in the foreground.
      _refreshWiFiData.add(null);
    }
  }
}

/// Helpful to observe the WiFi connection modification and to know the current
/// WiFi SSID
///
/// This class only observe the WiFi SSID when we need to observe it. Most of
/// the time, this is quiet and emit nothing
class _SsidWiFiObserverManager {
  final WiFiManager _wiFiManager;

  int _observerNb;
  StreamSubscription<bool> _observeConnection;
  String _wiFiSsid;
  StreamController<String> _wifiSsidController;
  LockUtility _lockUtility;

  /// Emit the current WiFi SSID when we change of WiFi
  /// Emit null when we are no more connected to WiFi
  Stream<String> get wiFiSsidStream => _wifiSsidController.stream;

  /// Get the current WiFi SSID
  Future<String> get wiFiSsid async {
    if (_wiFiSsid != null) {
      return _wiFiSsid;
    }

    if (_observeConnection != null) {
      await _refreshInfo(true);
      return _wiFiSsid;
    }

    return _wiFiManager.getWiFiSsid();
  }

  _SsidWiFiObserverManager(WiFiManager wiFiManager)
      : _wiFiManager = wiFiManager {
    _lockUtility = LockUtility();
    _observerNb = 0;
    _wifiSsidController = StreamController<String>.broadcast();
  }

  /// Generate an observer
  WiFiObserveSsid generateObserver() {
    return WiFiObserveSsid(this);
  }

  /// Called in order to fire the connection observing
  void _takeOne() {
    _observerNb++;

    if (_observeConnection == null) {
      _observeConnection = _wiFiManager
          ._observeConnection.needToRefreshWifiInfoStream
          .listen(_needToRefreshInfo);
    }
  }

  /// Called in order to verify if it's needed to stop to watch the WiFi modifs
  void _releaseOne() {
    _observerNb--;

    if (_observerNb == 0) {
      _observeConnection.cancel();
      _observeConnection = null;
      _wiFiSsid = null;
    }
  }

  /// Called when we need to refresh the WiFi info
  ///
  /// [connectedToWiFi] can be null, if we don't know the current WiFi state
  void _needToRefreshInfo(bool connectedToWiFi) {
    _refreshInfo(connectedToWiFi);
  }

  /// Refresh the WiFi info
  ///
  /// [connectedToWiFi] can be null, if we don't know the current WiFi state
  Future<void> _refreshInfo(bool connectedToWiFi) async {
    LockEntity entity = await _lockUtility.waitAndLock();

    String wiFiSsid;

    if (connectedToWiFi == null || connectedToWiFi) {
      wiFiSsid = await _wiFiManager.getWiFiSsid();
    }

    if (_wiFiSsid != wiFiSsid) {
      _wiFiSsid = wiFiSsid;
      _wifiSsidController.add(wiFiSsid);
      AppLogger().d("Got a new WiFI SSID: $wiFiSsid"); // TODO remove this
    }

    entity.freeLock();
  }
}

/// This class allows others to observe the WiFi SSID update
class WiFiObserveSsid {
  final _SsidWiFiObserverManager _manager;

  /// Return the current WiFi SSID value
  Future<String> get wiFiSsid => _manager.wiFiSsid;

  /// Emit the current WiFi SSID when we change of WiFi
  /// Emit null when we are no more connected to WiFi
  Stream<String> get wiFiSsidStream => _manager.wiFiSsidStream;

  /// Class constructor
  ///
  /// BEWARE don't forget to call the [close] method when we don't need to
  /// observe the SSID anymore
  WiFiObserveSsid(_SsidWiFiObserverManager manager) : _manager = manager {
    manager._takeOne();
  }

  /// Close all the dependencies of the class, needs to be called when this
  /// instance is no more useful
  void close() {
    _manager._releaseOne();
  }
}
