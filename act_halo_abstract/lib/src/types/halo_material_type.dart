// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_halo_abstract/src/abstract_halo_material.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// This defines the kind of supported material layer
class HaloMaterialType<T> extends Equatable {
  /// The type of Material
  final T type;

  /// The material layer
  final AbstractHaloMaterial haloMaterial;

  /// Class constructor
  const HaloMaterialType({
    required this.type,
    required this.haloMaterial,
  });

  @override
  List<Object?> get props => [type, haloMaterial];
}

/// Helpful class to manage [HaloMaterialType] enum
abstract class AbstractHaloMaterialTypeHelper<T> {
  /// The list of material services
  final Map<T, HaloMaterialType<T>> materialServices;

  /// Class constructor
  AbstractHaloMaterialTypeHelper({
    required this.materialServices,
  });

  /// Manage the close of all the resources at the end of the class
  /// Need to be called by the owner of the class
  /// It closes all the material services
  @mustCallSuper
  Future<void> close() async {
    final futures = <Future>[];

    for (final service in materialServices.values) {
      futures.add(service.haloMaterial.close());
    }

    await Future.wait(futures);
  }
}
