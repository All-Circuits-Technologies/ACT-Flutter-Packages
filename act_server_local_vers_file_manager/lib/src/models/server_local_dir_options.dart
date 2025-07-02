// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_server_local_vers_file_manager/src/constants/server_local_vers_file_constants.dart';
import 'package:equatable/equatable.dart';

/// This class is used to store the options for a server local directory.
class ServerLocalDirOptions extends Equatable {
  /// The key used to store the locales in the JSON.
  static const _localesKey = "locales";

  /// The key used to store the cache version option in the JSON.
  static const _cacheVersionKey = "cacheVersion";

  /// The key used to store the cache file option in the JSON.
  static const _cacheFileKey = "cacheFile";

  /// Optional locales to search localized files with.
  final List<Locale>? locales;

  /// Optional function for the computation of a file name given a version
  final VersionToFileNameParser? versionToFileName;

  /// Optional caching of version files requests
  final bool? cacheVersion;

  /// Optional caching of final files requests
  final bool? cacheFile;

  /// Class constructor
  const ServerLocalDirOptions({
    this.locales,
    this.versionToFileName,
    this.cacheVersion,
    this.cacheFile,
  });

  /// Returns a copy of this [ServerLocalDirOptions] with the given parameters.
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

  /// Parses a [ServerLocalDirOptions] from a JSON map.
  /// Returns `null` if the parsing fails.
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

  /// Contains the class properties
  @override
  List<Object?> get props => [locales, cacheVersion, cacheFile];
}
