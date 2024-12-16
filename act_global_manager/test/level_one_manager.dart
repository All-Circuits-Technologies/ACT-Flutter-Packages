// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:flutter/foundation.dart';

abstract class LevelOneBuilder<T extends LevelOneManager>
    extends ManagerBuilder<T> {
  final Type _depends;

  LevelOneBuilder(
    ClassFactory factory, {
    @required Type dpdOneDepends,
  })  : assert(dpdOneDepends != null),
        _depends = dpdOneDepends,
        super(factory);

  @override
  Iterable<Type> dependsOn() => [_depends];
}

abstract class LevelOneManager extends AbstractManager {
  final int magicNumber;

  LevelOneManager({
    @required this.magicNumber,
  })  : assert(magicNumber != null),
        super();

  @override
  Future<void> initManager() => null;
}
