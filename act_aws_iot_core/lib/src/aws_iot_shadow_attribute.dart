// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_aws_iot_core/src/aws_iot_named_shadow.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:mutex/mutex.dart';

/// This class is used to track an attribute of a shadow
class AwsIotShadowAttribute<T> {
  /// This is the named of the attribute
  final String _attributeName;

  /// Stream controller for the desired value
  final StreamController<T> _desiredStreamController;

  /// Stream controller for the reported value
  final StreamController<T> _reportedStreamController;

  /// This is the shadow used by the attribute
  final AwsIotNamedShadow _shadow;

  /// This is the mutex that protects the [_desiredValue]
  final Mutex _desiredValueMutex;

  /// This is the mutex that protects the [_reportedValue]
  final Mutex _reportedValueMutex;

  /// Subscription to the desired state of the shadow we are tracking
  final List<StreamSubscription> _streamSubscriptions;

  /// This is true if the attribute is writable
  final bool _writable;

  /// This is the function used to get the value of the attribute from the dynamic json value
  // We use the dynamic type here because we store the data as dynamic and cast its value to what we
  // expect to have.
  // ignore: avoid_annotating_with_dynamic
  final T? Function(dynamic jsonValue) _castValue;

  /// The desired value of the attribute
  T? _desiredValue;

  /// The reported value of the attribute
  T? _reportedValue;

  /// Stream for the desired value
  Stream<T> get desiredStream => _desiredStreamController.stream;

  /// Stream for the reported value
  Stream<T> get reportedStream => _reportedStreamController.stream;

  /// Get the desired value of the attribute
  T? get desiredValue => _desiredValue;

  /// Get the reported value of the attribute
  T? get reportedValue => _reportedValue;

  /// Class constructor.
  /// [castValue] can be set to specify how to cast the value from the json value to the attribute
  /// type. If not set, the default cast function will be used (which can handle primitive types).
  AwsIotShadowAttribute({
    required String attributeName,
    required AwsIotNamedShadow shadow,
    // We use the dynamic type here because we store the data as dynamic and cast its value to what we
    // expect to have.
    // ignore: avoid_annotating_with_dynamic
    T? Function(dynamic jsonValue)? castValue,
    bool writable = true,
  })  : _shadow = shadow,
        _attributeName = attributeName,
        _writable = writable,
        _castValue = castValue ?? _castPrimitiveType<T>,
        _desiredStreamController = StreamController<T>.broadcast(),
        _reportedStreamController = StreamController<T>.broadcast(),
        _streamSubscriptions = [],
        _desiredValueMutex = Mutex(),
        _reportedValueMutex = Mutex() {
    // Listen to the desired and reported state of the shadow
    _streamSubscriptions.addAll([
      shadow.desiredStateStream.listen(_onDesiredState),
      shadow.reportedStateStream.listen(_onReportedState),
    ]);

    // Get the initial values
    unawaited(_onDesiredState(shadow.desiredState));
    unawaited(_onReportedState(shadow.reportedState));
  }

  /// This method is called when the desired state of the shadow changes. It will update the
  /// [_desiredValue] if the desired value of the attribute has changed
  Future<void> _onDesiredState(
    Map<String, dynamic> desiredState,
  ) =>
      _desiredValueMutex.protect(
        () async {
          final newDesiredValue = _castValue(desiredState[_attributeName]);

          if (newDesiredValue == null || newDesiredValue == _desiredValue) {
            return;
          }

          _desiredValue = newDesiredValue;
          _desiredStreamController.add(newDesiredValue);
        },
      );

  /// This method is called when the reported state of the shadow changes. It will update the
  /// [_reportedValue] if the reported value of the attribute has changed
  Future<void> _onReportedState(
    Map<String, dynamic> reportedState,
  ) =>
      _reportedValueMutex.protect(
        () async {
          final newReportedValue = _castValue(reportedState[_attributeName]);

          if (newReportedValue == null || newReportedValue == _reportedValue) {
            return;
          }

          _reportedValue = newReportedValue;
          _reportedStreamController.add(newReportedValue);
        },
      );

  /// Change the desired value of the attribute
  Future<bool> setDesired(
    T newValue,
  ) async {
    if (!_writable) {
      appLogger().w('Attribute $_attributeName is not writable');
      return false;
    }

    return _shadow.requestUpdate(
      {_attributeName: newValue},
    );
  }

  /// This method can cast a dynamic value to a primitive type
  // We use the dynamic type here because we store the data as dynamic and cast its value to what we
  // expect to have.
  // ignore: avoid_annotating_with_dynamic
  static T? _castPrimitiveType<T>(dynamic jsonValue) {
    if (jsonValue is! T) {
      return null;
    }

    return jsonValue;
  }

  /// Call this method to dispose the streams
  Future<void> dispose() async {
    await Future.wait([
      ..._streamSubscriptions.map((sub) => sub.cancel()),
      _desiredStreamController.close(),
      _reportedStreamController.close(),
    ]);
  }
}
