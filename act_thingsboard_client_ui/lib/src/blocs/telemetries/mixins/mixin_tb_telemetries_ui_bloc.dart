// SPDX-FileCopyrightText: 2023, 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/act_thingsboard_client_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This callback is used to get the information of a thingsboard device
/// The first return element is a boolean and tells if a problem occurred in the process or not
/// The second return element is a nullable [DeviceInfo]
///
/// When we succeed to contact Thingsboard but the device is not known, the method will return
/// (true, null)
typedef GetDeviceInfo = Future<({bool success, DeviceInfo? deviceInfo})> Function();

/// This mixin is helpful to use the [TbTelemetriesUiBloc] and its states without extending it
mixin MixinTbTelemetriesUiBloc<Tb extends AbsTbServerReqManager,
    S extends MixinTbTelemetriesUiState<S>> on BlocForMixin<S> {
  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.clientAttributesKeys}
  /// The keys of client attributes to listen
  /// {@endtemplate}
  List<MixinTelemetriesKeys> get clientAttributesKeys => const [];

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.sharedAttributesKeys}
  /// The keys of shared attributes to listen
  /// {@endtemplate}
  List<MixinTelemetriesKeys> get sharedAttributesKeys => const [];

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.serverAttributesKeys}
  /// The keys of server attributes to listen
  /// {@endtemplate}
  List<MixinTelemetriesKeys> get serverAttributesKeys => const [];

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.timeSeriesKeys}
  /// The keys of time series attributes to listen
  /// {@endtemplate}
  List<MixinTelemetriesKeys> get timeSeriesKeys => const [];

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.getDeviceInfo}
  /// This method is used to get the information of the device we want to listen telemetries from
  /// {@endtemplate}
  GetDeviceInfo get getDeviceInfo;

  /// The telemetry handler
  TbTelemetryHandler? _tbTelemetryHandler;

  /// The subscription linked to the time series stream
  StreamSubscription? _timeSeriesSub;

  /// The subscription linked to the attributes stream
  StreamSubscription? _attributesSub;

  /// The subscription linked to the internet connectivity stream
  StreamSubscription? _internetSub;

  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<InitTbTelemetriesUiEvent>(_onInitOrRetryEvent);
    on<RetryInitTbTelemetriesUiEvent>(_onInitOrRetryEvent);
    on<NewTbTimeSeriesValuesUiEvent>(onNewTsValuesEvent);
    on<NewTbAttributesValuesUiEvent>(onNewAttributesValuesEvent);

    add(const InitTbTelemetriesUiEvent());
  }

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.onNewTsValuesEvent}
  /// Called when a [NewTbTimeSeriesValuesUiEvent] event is emitted
  /// {@endtemplate}
  @protected
  Future<void> onNewTsValuesEvent(
    NewTbTimeSeriesValuesUiEvent event,
    Emitter<S> emitter,
  ) async {
    emitter.call(state.copyWithNewValuesUiState(
      tsValues: event.tsValues,
    ));
  }

  /// {@template act_thingsboard_client_ui.MixinTbTelemetriesUiBloc.onNewAttributesValuesEvent}
  /// Called when a [NewTbAttributesValuesUiEvent] event is emitted
  /// {@endtemplate}
  @protected
  Future<void> onNewAttributesValuesEvent(
    NewTbAttributesValuesUiEvent event,
    Emitter<S> emitter,
  ) async {
    emitter.call(state.copyWithNewValuesUiState(
      attributesValues: event.attributesValues,
    ));
  }

  /// Called to initialise the telemetry handler, also called when doing a retry after an error
  /// occurred.
  Future<void> _onInitOrRetryEvent<T extends BlocEventForMixin>(
    T event,
    Emitter<S> emitter,
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
      appLogger().w("Can't subscribe to listen some time series and client attributes");
      emitter.call(state.copyWithErrorUiState(
        genericError: TbTelemetriesUiError.serverError,
      ));
      return;
    }

    final currentTsValues = _tbTelemetryHandler!.getTsValues();
    final currentAttrValues = _tbTelemetryHandler!.getAttributeValues();

    /// Call the loading Ui State with telemetries and attributes values
    emitter.call(state.copyWithTelemetryInit(
      device: deviceInfo,
      tsValues: currentTsValues,
      attributesValues: currentAttrValues,
    ));
  }

  /// Called to init the [TbTelemetryHandler] linked to this BLoC
  Future<DeviceInfo?> _initTelemetryHandler(
    Emitter<S> emitter,
  ) async {
    if (!await _manageInternetConnectivity()) {
      appLogger().w("We can't init the telemetry subscription: the phone isn't connected to "
          "internet");
      emitter.call(state.copyWithErrorUiState(
        genericError: TbTelemetriesUiError.noInternetAtStart,
      ));
      return null;
    }

    final tbDevicesService = globalGetIt().get<Tb>().devicesService;

    final result = await getDeviceInfo();

    if (!result.success) {
      appLogger().w("A problem occurred when tried to get the info of the thingsboard device, when "
          "getting to try to get its telemetries");
      emitter.call(state.copyWithErrorUiState(
        genericError: TbTelemetriesUiError.serverError,
      ));
      return null;
    }

    if (result.deviceInfo == null) {
      appLogger().w("The wanted device info hasn't been found in thingsboard, when getting to try "
          "to get its telemetries");
      emitter.call(state.copyWithErrorUiState(
        genericError: TbTelemetriesUiError.unknownDevice,
      ));
      return null;
    }

    final deviceId = result.deviceInfo!.id?.id;

    if (deviceId == null) {
      appLogger().w("A problem occurred when tried to get the device id of the thingsboard device, "
          "when getting to try to get its telemetries");
      emitter.call(state.copyWithErrorUiState(
        genericError: TbTelemetriesUiError.serverError,
      ));
      return null;
    }

    final handler = tbDevicesService.createTelemetryHandler(deviceId);
    _tbTelemetryHandler = handler;
    _timeSeriesSub = handler.timeSeriesStream.listen(_onTimeSeriesUpdate);
    _attributesSub = handler.attributesStream.listen(_onAttributesUpdate);

    return result.deviceInfo;
  }

  /// This manages the internet connectivity in the [_initTelemetryHandler] method
  Future<bool> _manageInternetConnectivity() async {
    final internetManager = globalGetIt().get<InternetConnectivityManager>();

    if (internetManager.hasConnection) {
      // Nothing has to be done
      return true;
    }

    _internetSub ??= internetManager.hasInternetStream.listen(_onInternetUpdate);

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
  void _onTimeSeriesUpdate(Map<String, TbTsValue> values) {
    add(NewTbTimeSeriesValuesUiEvent(tsValues: values));
  }

  /// Called when the attribute values are updated
  void _onAttributesUpdate(Map<String, TbExtAttributeData> values) {
    add(NewTbAttributesValuesUiEvent(attributesValues: values));
  }

  /// Get the [GetDeviceInfo] callback from the the given [deviceName]
  static GetDeviceInfo getCallbackFromDeviceName<Tb extends AbsTbServerReqManager>({
    required String deviceName,
  }) =>
      () async => globalGetIt().get<Tb>().devicesService.getCustomerDeviceByName(
            deviceName: deviceName,
          );

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
