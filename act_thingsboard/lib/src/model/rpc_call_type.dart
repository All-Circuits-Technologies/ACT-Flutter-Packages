// Copyright (c) 2020. BMS Circuits

/// Heat mode to power the water heater.
enum RpcCallType {
  oneway,
  twoway,
}

/// Attribute type extension methods
extension RpcCallTypeExension on RpcCallType {
  /// Return text of update state.
  String get text {
    return this.toString().split('.').last;
  }
}
