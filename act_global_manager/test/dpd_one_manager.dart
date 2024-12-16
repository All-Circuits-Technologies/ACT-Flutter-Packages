// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';

abstract class DpdOneBuilder<T extends DpdOneManager>
    extends ManagerBuilder<T> {
  DpdOneBuilder(
    ClassFactory factory,
  ) : super(factory);

  @override
  Iterable<Type> dependsOn() => [];
}

abstract class DpdOneManager extends AbstractManager {
  DpdOneManager() : super();

  @override
  Future<void> initManager() => null;
}
