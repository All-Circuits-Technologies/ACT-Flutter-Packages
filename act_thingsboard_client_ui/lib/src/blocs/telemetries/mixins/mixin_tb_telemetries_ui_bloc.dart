// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_bloc.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_event.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/tb_telemetries_ui_state.dart';
import 'package:act_thingsboard_client_ui/src/blocs/telemetries/types/tb_telemetry_ui_state_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Used to create a new event for storing the [tbUiState] and [stateType] in the linked bloc state
typedef CreateNewStateEvent<T> = T Function(
  TbTelemetriesUiState tbUiState,
  TbTelemetryUiStateType stateType,
);

/// This mixin is helpful to use the [TbTelemetriesUiBloc] and its states without extending it
mixin MixinTbTelemetriesUiBloc<NewStateEvent extends Event, Event, State>
    on Bloc<Event, State> {
  /// The thingsboard telemetries ui bloc used to receive update on attributes and time series
  /// modification
  late final TbTelemetriesUiBloc _telemetriesBloc;

  /// Subscription on new state
  late final StreamSubscription _onNewStateSub;

  /// If [_createNewStateEvent] is not null and when the states linked to [TbTelemetriesUiBloc] are
  /// updated, we create a new event by calling this method and calls [onNewTelemetriesUiState]
  /// If [_createNewStateEvent] is null, the method [onNewTelemetriesUiState] is never called and
  /// you won't receive state update from the [TbTelemetriesUiBloc] bloc
  late final CreateNewStateEvent<NewStateEvent>? _createNewStateEvent;

  /// "Constructs" the mixin and creates the [TbTelemetriesUiBloc] linked with all the needed
  /// configurations.
  ///
  /// [getDeviceInfo] is used to get the info of the device you want to listen
  ///
  /// Has to be called in the constructor body of the main block.
  @protected
  void constructTbTelemUiBloc<
      Ca extends MixinTelemetriesKeys,
      Sha extends MixinTelemetriesKeys,
      Sea extends MixinTelemetriesKeys,
      Ts extends MixinTelemetriesKeys>({
    required GetDeviceInfo getDeviceInfo,
    CreateNewStateEvent<NewStateEvent>? createNewStateEvent,
    List<Ca> clientAttributesKeys = const [],
    List<Sha> sharedAttributesKeys = const [],
    List<Sea> serverAttributesKeys = const [],
    List<Ts> timeSeriesKeys = const [],
  }) {
    _telemetriesBloc = TbTelemetriesUiBloc(
      getDeviceInfo: getDeviceInfo,
      clientAttributesKeys: clientAttributesKeys,
      sharedAttributesKeys: sharedAttributesKeys,
      serverAttributesKeys: serverAttributesKeys,
      timeSeriesKeys: timeSeriesKeys,
    );

    _createNewStateEvent = createNewStateEvent;

    _onNewStateSub = _telemetriesBloc.stream.listen(_onNewTelemetriesUiState);

    if (createNewStateEvent != null) {
      on<NewStateEvent>(onNewTelemetriesUiState);
    }
  }

  /// "Constructs" the mixin and creates the [TbTelemetriesUiBloc] linked with all the needed
  /// configurations.
  ///
  /// [deviceName] is used to find the device you want to listen
  ///
  /// Has to be called in the constructor body of the main block.
  @protected
  void constructTbTelemUiBlocWithDeviceInfoFromName<
          Ca extends MixinTelemetriesKeys,
          Sha extends MixinTelemetriesKeys,
          Sea extends MixinTelemetriesKeys,
          Ts extends MixinTelemetriesKeys>({
    required String deviceName,
    CreateNewStateEvent<NewStateEvent>? createNewStateEvent,
    List<Ca> clientAttributesKeys = const [],
    List<Sha> sharedAttributesKeys = const [],
    List<Sea> serverAttributesKeys = const [],
    List<Ts> timeSeriesKeys = const [],
  }) =>
      constructTbTelemUiBloc(
        getDeviceInfo: () async => globalGetIt()
            .get<ThingsboardManager>()
            .devicesService
            .getCustomerDeviceByName(
              deviceName: deviceName,
            ),
        createNewStateEvent: createNewStateEvent,
        timeSeriesKeys: timeSeriesKeys,
        serverAttributesKeys: serverAttributesKeys,
        sharedAttributesKeys: sharedAttributesKeys,
        clientAttributesKeys: clientAttributesKeys,
      );

  /// Called when a new state is available from the linked [TbTelemetriesUiBloc]
  ///
  /// If needed it adds a new event in the main bloc
  void _onNewTelemetriesUiState(TbTelemetriesUiState telemetriesUiState) {
    if (_createNewStateEvent == null) {
      // Nothing has to be done
      return;
    }

    TbTelemetryUiStateType type;

    switch (telemetriesUiState.runtimeType) {
      case const (TbAttributesNewValuesUiState):
        type = TbTelemetryUiStateType.newAttributes;
        break;
      case const (TbTimeSeriesNewValuesUiState):
        type = TbTelemetryUiStateType.newTimeSeries;
        break;
      default:
        type = TbTelemetryUiStateType.other;
        break;
    }

    add(_createNewStateEvent!(telemetriesUiState, type));
  }

  /// Called when a new state is available from the linked [TbTelemetriesUiBloc] bloc.
  ///
  /// This is useful when you want to rebuild your view when it happens.
  @protected
  Future<void> onNewTelemetriesUiState(
    NewStateEvent event,
    Emitter<State> emitter,
  );

  /// Call to retry the thingsboard telemetries init in the [TbTelemetriesUiBloc]
  void addRetryTbTelemetriesInit() =>
      _telemetriesBloc.add(const RetryInitTbTelemetriesUiEvent());

  /// Called when the BLoC close method is called
  @override
  Future<void> close() async {
    await _onNewStateSub.cancel();
    await _telemetriesBloc.close();

    return super.close();
  }
}
