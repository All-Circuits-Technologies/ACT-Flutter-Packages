// Copyright (c) 2020. BMS Circuits

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_thingsboard/act_thingsboard.dart';
import 'package:act_thingsboard/src/authentication_manager.dart';
import 'package:act_thingsboard/src/device_manager.dart';
import 'package:act_thingsboard/src/model/attribute_name.dart';
import 'package:act_thingsboard/src/token_manager.dart';
import 'package:flutter/foundation.dart';

// Export the global manager to avoid to have multiple files to import for using
// global manager
export 'package:act_global_manager/act_global_manager.dart';

abstract class TbGlobalManager extends GlobalManager {
  TbGlobalManager.create() : super.create();

  @override
  @mustCallSuper
  void init() {
    super.init();

    AbstractAttributeNameHelper attributesHelper = createHelper();

    registerSingletonAsync<AuthenticationManager>(AuthenticationBuilder());

    registerSingletonAsync<DeviceManager>(DeviceBuilder(
      attributesHelper: attributesHelper,
      tbPropertiesManagerDependency: getPropertiesManagerType(),
    ));

    registerSingletonAsync<TokenManager>(TokenBuilder(
      tbSecretsManagerDependency: getSecretsManagerType(),
    ));
  }

  /// Return the final type of the SecretsManager
  ///
  /// This is used to declare dependence for the other managers
  @protected
  Type getSecretsManagerType();

  /// Return the TbSecretsManager instance
  @protected
  TbSecretsManager getInternSecretsManager();

  /// Return the final type of the PropertiesManager
  ///
  /// This is used to declare dependence for the other managers
  @protected
  Type getPropertiesManagerType();

  /// Return the TbPropertiesManager instance
  @protected
  TbPropertiesManager getInterPropertiesManager();

  /// Create and return the AttributeNameHelper to use in the app
  @protected
  AbstractAttributeNameHelper createHelper();

  /// Get the [TbPropertiesManager] instance
  ///
  /// It's necessary to use this method on this package, but in the Application
  /// is strongly advised to use [GlobalGetIt] static method.
  static TbPropertiesManager getPropertiesManager() =>
      (GlobalManager.instance as TbGlobalManager).getInterPropertiesManager();

  /// Get the [TbSecretsManager] instance
  ///
  /// It's necessary to use this method on this package, but in the Application
  /// is strongly advised to use [GlobalGetIt] static method.
  static TbSecretsManager getSecretsManager() =>
      (GlobalManager.instance as TbGlobalManager).getInternSecretsManager();
}
