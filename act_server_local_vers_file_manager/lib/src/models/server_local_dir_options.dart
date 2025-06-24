// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_local_vers_file_manager/src/constants/server_local_vers_file_constants.dart';
import 'package:equatable/equatable.dart';

class ServerLocalDirOptions extends Equatable {
  static const _localesKey = "locales";
  static const _cacheVersionKey = "cacheVersion";
  static const _cacheFileKey = "cacheFile";

  /// Optional locales to search localized files with.
  /// See also [systemLocale] which may be enough.
  final List<Locale>? locales;

  /// Optional function for the computation of a file name given a version
  final VersionToFileNameParser? versionToFileName;

  /// Optional caching of version files requests
  final bool? cacheVersion;

  /// Optional caching of final files requests
  final bool? cacheFile;

  const ServerLocalDirOptions({
    this.locales,
    this.versionToFileName,
    this.cacheVersion,
    this.cacheFile,
  });

  ServerLocalDirOptions copyWith({
    List<Locale>? locales,
    bool forceLocalesValue = false,
    VersionToFileNameParser? versionToFileName,
    bool forceVersionToFileNameValue = false,
    bool? cacheVersion,
    bool forceCacheVersionValue = false,
    bool? cacheFile,
    bool forceCacheFileValue = false,
  }) =>
      ServerLocalDirOptions(
        locales: locales ?? (forceLocalesValue ? null : this.locales),
        versionToFileName:
            versionToFileName ?? (forceVersionToFileNameValue ? null : this.versionToFileName),
        cacheVersion: cacheVersion ?? (forceCacheVersionValue ? null : this.cacheVersion),
        cacheFile: cacheFile ?? (forceCacheFileValue ? null : this.cacheFile),
      );

  static ServerLocalDirOptions? parseFromJson(Map<String, dynamic> json) {
    final loggerManager = appLogger();
    final localsResult = JsonUtility.getElementsList<Locale, String>(
      json: json,
      key: _localesKey,
      canBeUndefined: true,
      castElemValueFunc: (toCast) => LocaleUtility.localeFromString(string: toCast),
      loggerManager: loggerManager,
    );

    final cacheVersionResult = JsonUtility.getOnePrimaryElement<bool>(
      json: json,
      key: _cacheVersionKey,
      canBeUndefined: true,
      loggerManager: loggerManager,
    );

    final cacheFileResult = JsonUtility.getOnePrimaryElement<bool>(
      json: json,
      key: _cacheFileKey,
      canBeUndefined: true,
      loggerManager: loggerManager,
    );

    if (!localsResult.isOk || !cacheVersionResult.isOk || !cacheFileResult.isOk) {
      appLogger().w("We failed to parse the ServerLocalDirOptions model from JSON");
      return null;
    }

    return ServerLocalDirOptions(
      locales: localsResult.value,
      cacheFile: cacheFileResult.value,
      cacheVersion: cacheVersionResult.value,
    );
  }

  @override
  List<Object?> get props => [locales, cacheVersion, cacheFile];
}
