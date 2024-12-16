// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_error.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_event.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This callback is used to get the information of a thingsboard device
/// The first return element is a boolean and tells if a problem occurred in the process or not
/// The second return element is a nullable [DeviceInfo]
///
/// When we succeed to contact Thingsboard but the device is not known, the method will return
/// (true, null)
typedef GetDeviceInfo = Future<(bool, DeviceInfo?)> Function();

/// This bloc is used to get and display telemetries in views
///
/// It can be used as it is (when you don't need other BloC process in your view) or with another
/// BLoC, using the [MixinTbTelemetriesUiBloc] mixin
class TbTelemetriesUiBloc<
        Ca extends MixinTelemetriesKeys,
        Sha extends MixinTelemetriesKeys,
        Sea extends MixinTelemetriesKeys,
        Ts extends MixinTelemetriesKeys>
    extends Bloc<TbTelemetriesUiEvent, TbTelemetriesUiState> {
  /// The keys of client attributes to listen
  final List<Ca> clientAttributesKeys;

  /// The keys of shared attributes to listen
  final List<Sha> sharedAttributesKeys;

  /// The keys of server attributes to listen
  final List<Sea> serverAttributesKeys;

  /// The keys of time series attributes to listen
  final List<Ts> timeSeriesKeys;

  /// This method is used to get the information of the device we want to listen telemetries from
  final GetDeviceInfo _getDeviceInfo;

  /// The telemetry handler
  TbTelemetryHandler? _tbTelemetryHandler;

  /// The subscription linked to the time series stream
  StreamSubscription? _timeSeriesSub;

  /// The subscription linked to the attributes stream
  StreamSubscription? _attributesSub;

  /// The subscription linked to the internet connectivity stream
  StreamSubscription? _internetSub;

  /// Class constructor
  TbTelemetriesUiBloc({
    required GetDeviceInfo getDeviceInfo,
    this.clientAttributesKeys = const [],
    this.sharedAttributesKeys = const [],
    this.serverAttributesKeys = const [],
    this.timeSeriesKeys = const [],
  })  : _getDeviceInfo = getDeviceInfo,
        super(TbTelemetriesInitUiState()) {
    on<InitTbTelemetriesUiEvent>(_onInitOrRetryEvent);
    on<RetryInitTbTelemetriesUiEvent>(_onInitOrRetryEvent);
    on<NewTbTimeSeriesValuesUiEvent>(_onNewTsValuesEvent);
    on<NewTbAttributesValuesUiEvent>(_onNewAttributesValuesEvent);

    add(const InitTbTelemetriesUiEvent());
  }

  /// Called to initialise the telemetry handler, also called when doing a retry after an error
  /// occurred.
  Future<void> _onInitOrRetryEvent<T extends TbTelemetriesUiEvent>(
    T event,
    Emitter<TbTelemetriesUiState> emitter,
  ) async {
    DeviceInfo? deviceInfo;

    if (_tbTelemetryHandler == null) {
      deviceInfo = await _initTelemetryHandler(emitter);

      if (deviceInfo == null) {
        // A problem occurred, we can't continue
        return;
      }
    }

    if (_tbTelemetryHandler!.areWeListeningTelemetries) {
      // Nothing has to be done
      return;
    }

    if (!(await _tbTelemetryHandler!.addKeys(
      tsKeys: timeSeriesKeys,
      sharedKeys: sharedAttributesKeys,
      serverKeys: serverAttributesKeys,
      clientKeys: clientAttributesKeys,
    ))) {
      appLogger().w(
          "Can't subscribe to listen some time series and client attributes");
      emitter.call(TbTelemetriesErrorUiState(
        previousState: state,
        genericError: TbTelemetriesUiError.serverError,
      ));
      return;
    }

    final currentTsValues = _tbTelemetryHandler!.getTsValues();
    final currentAttrValues = _tbTelemetryHandler!.getAttributeValues();

    /// Call the loading Ui State with telemetries and attributes values
    emitter.call(TbTelemetriesLoadingUiState(
      previousState: state,
      telemetryLoading: !_haveIAtLeastOneExpectedTelemetry(
        currentTsValues: currentTsValues,
        currentAttributes: currentAttrValues,
        clientAttributesKeys: clientAttributesKeys,
        sharedAttributesKeys: sharedAttributesKeys,
        serverAttributesKeys: serverAttributesKeys,
        timeSeriesKeys: timeSeriesKeys,
      ),
      device: deviceInfo,
      tsValues: currentTsValues,
      attributesValues: currentAttrValues,
    ));
  }

  /// Called to init the [TbTelemetryHandler] linked to this BLoC
  Future<DeviceInfo?> _initTelemetryHandler(
    Emitter<TbTelemetriesUiState> emitter,
  ) async {
    if (!await _manageInternetConnectivity()) {
      appLogger().w(
          "We can't init the telemetry subscription: the phone isn't connected to "
          "internet");
      emitter.call(TbTelemetriesErrorUiState(
        previousState: state,
        genericError: TbTelemetriesUiError.noInternetAtStart,
      ));
      return null;
    }

    final tbDevicesService =
        globalGetIt().get<ThingsboardManager>().devicesService;

    final (result, deviceInfo) = await _getDeviceInfo();

    if (!result) {
      appLogger().w(
          "A problem occurred when tried to get the info of the thingsboard device, when "
          "getting to try to get its telemetries");
      emitter.call(TbTelemetriesErrorUiState(
        previousState: state,
        genericError: TbTelemetriesUiError.serverError,
      ));
      return null;
    }

    if (deviceInfo == null) {
      appLogger().w(
          "The wanted device info hasn't been found in thingsboard, when getting to try "
          "to get its telemetries");
      emitter.call(TbTelemetriesErrorUiState(
        previousState: state,
        genericError: TbTelemetriesUiError.unknownDevice,
      ));
      return null;
    }

    final deviceId = deviceInfo.id?.id;

    if (deviceId == null) {
      appLogger().w(
          "A problem occurred when tried to get the device id of the thingsboard device, "
          "when getting to try to get its telemetries");
      emitter.call(TbTelemetriesErrorUiState(
        previousState: state,
        genericError: TbTelemetriesUiError.serverError,
      ));
      return null;
    }

    final handler = tbDevicesService.createTelemetryHandler(deviceId);
    _tbTelemetryHandler = handler;
    _timeSeriesSub = handler.timeSeriesStream.listen(_onTimeSeriesUpdate);
    _attributesSub = handler.attributesStream.listen(_onAttributesUpdate);

    return deviceInfo;
  }

  /// This manages the internet connectivity in the [_initTelemetryHandler] method
  Future<bool> _manageInternetConnectivity() async {
    final internetManager = globalGetIt().get<InternetConnectivityManager>();

    if (internetManager.hasConnection) {
      // Nothing has to be done
      return true;
    }

    _internetSub ??=
        internetManager.hasConnectionStream.listen(_onInternetUpdate);

    await _onInternetUpdate(internetManager.hasConnection);
    return false;
  }

  /// Called when the internet connection has been updated
  Future<void> _onInternetUpdate(bool hasConnection) async {
    if (!hasConnection) {
      // Nothing has to be done for now
      return;
    }

    await _internetSub?.cancel();
    _internetSub = null;
    add(const RetryInitTbTelemetriesUiEvent());
  }

  /// Called when the time series values are updated
  void _onTimeSeriesUpdate(Map<String, TsValue> values) {
    add(NewTbTimeSeriesValuesUiEvent(tsValues: values));
  }

  /// Called when a [NewTbTimeSeriesValuesUiEvent] event is emitted
  Future<void> _onNewTsValuesEvent(
    NewTbTimeSeriesValuesUiEvent event,
    Emitter<TbTelemetriesUiState> emitter,
  ) async {
    emitter.call(TbTimeSeriesNewValuesUiState(
      previousState: state,
      tsValues: event.tsValues,
    ));
  }

  /// Called when the attribute values are updated
  void _onAttributesUpdate(Map<String, TbExtAttributeData> values) {
    add(NewTbAttributesValuesUiEvent(attributesValues: values));
  }

  /// Called when a [NewTbAttributesValuesUiEvent] event is emitted
  Future<void> _onNewAttributesValuesEvent(
    NewTbAttributesValuesUiEvent event,
    Emitter<TbTelemetriesUiState> emitter,
  ) async {
    emitter.call(TbAttributesNewValuesUiState(
      previousState: state,
      attributesValues: event.attributesValues,
    ));
  }

  /// Say if in cache we have at least one expected telemetry (which means that somehow, one page
  /// has already loaded some data)
  static bool _haveIAtLeastOneExpectedTelemetry({
    required Map<String, TsValue> currentTsValues,
    required Map<String, TbExtAttributeData> currentAttributes,
    required List<MixinTelemetriesKeys> clientAttributesKeys,
    required List<MixinTelemetriesKeys> sharedAttributesKeys,
    required List<MixinTelemetriesKeys> serverAttributesKeys,
    required List<MixinTelemetriesKeys> timeSeriesKeys,
  }) {
    bool findKeys(
      List<String> tmpTelemetriesKeys,
      List<MixinTelemetriesKeys> telemetriesKeys,
    ) {
      for (final telemKey in telemetriesKeys) {
        if (tmpTelemetriesKeys.contains(telemKey.getTbKey())) {
          return true;
        }
      }

      return false;
    }

    final currAttrKeys = currentAttributes.keys.toList();

    if (findKeys(currAttrKeys, clientAttributesKeys) ||
        findKeys(currAttrKeys, sharedAttributesKeys) ||
        findKeys(currAttrKeys, serverAttributesKeys)) {
      return true;
    }

    final currTsKeys = currentTsValues.keys.toList();

    return findKeys(currTsKeys, timeSeriesKeys);
  }

  /// Called when the BLoC close method is called
  @override
  Future<void> close() async {
    final futures = <Future>[
      if (_timeSeriesSub != null) _timeSeriesSub!.cancel(),
      if (_attributesSub != null) _attributesSub!.cancel(),
      if (_internetSub != null) _internetSub!.cancel(),
      if (_tbTelemetryHandler != null) _tbTelemetryHandler!.close(),
    ];

    await Future.wait(futures);

    await super.close();
  }
}
