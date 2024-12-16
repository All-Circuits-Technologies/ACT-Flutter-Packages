// Copyright (c) 2020. BMS Circuits

import 'dpd_one_manager.dart';

class DpdTwoBuilder extends DpdOneBuilder<DpdTwoManager> {
  DpdTwoBuilder() : super(() => DpdTwoManager());

  @override
  Iterable<Type> dependsOn() => [];
}

class DpdTwoManager extends DpdOneManager {
  DpdTwoManager() : super();
}
