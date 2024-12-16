// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/tb_global_manager.dart';

/// Web socket attribute in the [WebSocketReceiveMessage]
class WsAttribute {
  String name;
  DateTime latestValueDatetime;
  Map<DateTime, String> values = {};

  /// Construct the object from a json list ([values])
  ///
  /// The [values] contains a list of values of this attribute. [name] is the
  /// name of the attribute to parse, [latestValue] is the timestamp of this
  /// attribute latest value
  WsAttribute.fromJson(
    String name,
    int latestValue,
    List<dynamic> values,
  ) {
    this.name = name;
    this.latestValueDatetime = DateTime.fromMillisecondsSinceEpoch(
      latestValue,
      isUtc: true,
    );

    values.forEach((element) {
      if (element is List<dynamic>) {
        List<dynamic> value = element;

        if (value.length != 2) {
          AppLogger().w("A problem occurred while parsing the values got "
              "from the web socket: $name");
          return;
        }

        if (value[0] is! int) {
          AppLogger().w("We expect to find a timestamp in index 0, but "
              "found: ${value[0]}");
          return;
        }

        if (value[1] is! String) {
          AppLogger().w("We expect to find a string value in index 1, "
              "but found: ${value[1]}");
          return;
        }

        DateTime ts = DateTime.fromMillisecondsSinceEpoch(
          value[0] as int,
          isUtc: true,
        );

        this.values[ts] = value[1] as String;
      }
    });
  }

  /// Returns true if the latest value isn't equal to null and if values
  /// contains the latest known value
  bool get valid =>
      (latestValueDatetime != null) && values.containsKey(latestValueDatetime);

  /// Get the latest value of the web socket attribute
  String get latestValue {
    if (!valid) {
      return null;
    }

    return values[latestValueDatetime];
  }
}

/// Message received from the web socket server
class WebSocketReceiveMessage {
  static const String _subscriptionIdKey = "subscriptionId";
  static const String _errorCodeKey = "errorCode";
  static const String _errorMsgKey = "errorMsg";
  static const String _dataKey = "data";
  static const String _latestValuesKey = "latestValues";

  int subscriptionId;
  int errorCode;
  String errorMsg;
  Map<String, WsAttribute> data = {};

  /// Build a [WebSocketReceiveMessage] from a [json]
  ///
  /// What is expected, ex:
  ///{
  ///   "subscriptionId": 4,
  ///   "errorCode": 0,
  ///   "errorMsg": null,
  ///   "data": {
  ///       "active": [
  ///           [
  ///               1586517243177,
  ///               "false"
  ///           ]
  ///       ],
  ///       "claimingAllowed": [
  ///           [
  ///               1587387316517,
  ///               "true"
  ///           ]
  ///       ],
  ///       "downloadPassword": [
  ///           [
  ///               1585854280347,
  ///               "h6d8OwzJUCnT"
  ///           ]
  ///       ],
  ///       "test": [
  ///           [
  ///               1586452139563,
  ///               "true"
  ///           ],
  ///           [
  ///               1587391944756,
  ///               "test2"
  ///           ]
  ///       ]
  ///   },
  ///   "latestValues": {
  ///       "test": 1587391944756,
  ///       "active": 1586517243177,
  ///       "downloadPassword": 1585854280347,
  ///       "claimingAllowed": 1587387316517
  ///   }
  ///}
  ///
  /// If an attribute is in latestValues it is also in data
  WebSocketReceiveMessage.fromJson(Map<String, dynamic> json) {
    if (json[_subscriptionIdKey] is int) {
      subscriptionId = json[_subscriptionIdKey] as int;
    }

    if (json[_errorCodeKey] is int) {
      errorCode = json[_errorCodeKey] as int;
    }

    if (json[_errorMsgKey] is String) {
      errorMsg = json[_errorMsgKey] as String;
    }

    Map<String, dynamic> tmpData;
    Map<String, dynamic> tmpLatestValues;

    if (json[_dataKey] is Map<String, dynamic>) {
      tmpData = json[_dataKey] as Map<String, dynamic>;
    }

    if (json[_latestValuesKey] is Map<String, dynamic>) {
      tmpLatestValues = json[_latestValuesKey] as Map<String, dynamic>;
    }

    if (tmpLatestValues == null || tmpLatestValues == null) {
      return;
    }

    tmpLatestValues.forEach((String name, dynamic tmpLatestValueTs) {
      if (tmpLatestValueTs is! int) {
        AppLogger().w("The latest value is not an integer: "
            "$tmpLatestValueTs");
        return;
      }

      int latestValueTs = tmpLatestValueTs as int;

      if (tmpData[name] is! List<dynamic>) {
        AppLogger().w("The $name attribute has no data from ws message");
        return;
      }

      List<dynamic> values = tmpData[name] as List<dynamic>;

      var wsAttr = WsAttribute.fromJson(name, latestValueTs, values);

      if (!wsAttr.valid) {
        AppLogger().w("The data $name is invalid for the web socket");
        return;
      }

      data[name] = wsAttr;
    });
  }
}
