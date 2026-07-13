// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_licenses_manager/src/models/licenses_keys_info_model.dart';
import 'package:act_licenses_manager/src/models/licenses_text_model.dart';

/// This mixin contains the configuration variables for the licenses manager.
mixin MixinLicensesConfig on AbstractConfigManager {
  /// The config variable to get the licenses of elements (packages, fonts, app, etc...).
  ///
  /// The value of this config variable should be a map with the following structure:
  /// ```json
  /// {
  ///   "package1": ["MIT", "GPL-3.0"],
  ///   "package2": ["Apache-2.0"]
  /// }
  /// ```
  final licensesExtraElements =
      const NotNullParserConfigVar<LicensesKeysInfoModel, Map<String, dynamic>>(
        "licenses.extraElements",
        parser: LicensesKeysInfoModel.fromJson,
        defaultValue: LicensesKeysInfoModel.empty(),
      );

  /// The config variable to get the list of assets folders to load the licenses from.
  ///
  /// If empty or not defined, the manager won't load any license from assets.
  ///
  /// Those folders should be defined in the pubspec.yaml file of the application as assets.
  ///
  /// The files name must match the license keys defined in the [licensesExtraElements] config
  /// variable, with a .txt extension.
  ///
  /// By default, we first look for the licenses in the [licensesTexts] config variable, then in the
  /// assets folders defined in this config variable.
  final licensesAssetsFolders = const ConfigVarList<String>("licenses.assetsFolders");

  /// The config variable to get the licenses texts.
  ///
  /// The value of this config variable should be a map with the following structure:
  /// ```json
  /// {
  ///   "MIT": "MIT License text",
  ///   "GPL-3.0": "GPL-3.0 License text",
  ///   "Apache-2.0": "Apache-2.0 License text"
  /// }
  /// ```
  ///
  /// If a license file is defined in the assets folders defined in the [licensesAssetsFolders]
  /// config variable, this text will take precedence over the asset file.
  final licensesTexts = const NotNullParserConfigVar<LicensesTextModel, Map<String, dynamic>>(
    "licenses.texts",
    parser: LicensesTextModel.fromJson,
    defaultValue: LicensesTextModel.empty(),
  );
}
