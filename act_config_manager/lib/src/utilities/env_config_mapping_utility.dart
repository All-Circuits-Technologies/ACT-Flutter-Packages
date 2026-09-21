// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/utilities/config_asset_loader.dart';
import 'package:act_dart_config_manager/act_dart_config_manager.dart';

/// This class contains useful methods to load and parse the env config mapping file from assets.
///
/// This file is used to build a config structure from env variables.
sealed class EnvConfigMappingUtility {
  /// This method returns the list of models to use in order to build the config object from env
  /// variables.
  ///
  /// If a problem occurred when loading the env config mapping file, an exception is raised. If the
  /// file is not found, the method returns an empty list.
  static Future<List<EnvConfigMappingModel>> fromAssetBundle(String path) async {
    final content = await ConfigAssetLoader.loadRaw(path);
    return EnvConfigMappingParser.fromContent(content);
  }
}
