// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_logging_manager/src/models/http_log.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';

/// Builder of the derived [HttpLoggingManager]
abstract class AbsHttpLoggingBuilder<M extends HttpLoggingManager> extends AbsManagerBuilder<M> {
  /// Class constructor
  const AbsHttpLoggingBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// Builder of the [HttpLoggingManager]
class HttpLoggingBuilder extends AbsHttpLoggingBuilder<HttpLoggingManager> {
  /// Class constructor
  const HttpLoggingBuilder() : super(HttpLoggingManager.new);
}

/// This class is used to manage the logging of http requests
class HttpLoggingManager extends AbsWithLifeCycle {
  /// Stream controller for the http logs
  final StreamController<HttpLog> _logStreamController;

  /// Optional source information to add to each log
  late final String? sourceInfo;

  /// Stream getter for the http logs
  Stream<HttpLog> get logStream => _logStreamController.stream;

  /// Default constructor
  HttpLoggingManager() : _logStreamController = StreamController<HttpLog>.broadcast();

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    sourceInfo = await getSourceInfo();
  }

  /// {@template act_http_logging_manager.HttpLoggingManager.getSourceInfo}
  /// Get the source information to add to each log
  /// {@endtemplate}
  @protected
  Future<String?> getSourceInfo() async => null;

  /// Add a new log to the stream
  void addLog(HttpLog log) {
    HttpLog tmpLog;
    if (sourceInfo != null) {
      tmpLog = log.copyWith(sourceInfo: sourceInfo);
    } else {
      tmpLog = log;
    }

    appLogger().log(tmpLog.logLevel, tmpLog.formattedLogMsg);
    _logStreamController.add(tmpLog);
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _logStreamController.close();
    return super.disposeLifeCycle();
  }
}
