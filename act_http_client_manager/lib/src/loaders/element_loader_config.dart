// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_http_client_manager/src/loaders/abs_element_loader.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This is the config which helps to request the elements from provider
class ElementLoaderConfig<T> extends Equatable {
  /// This is the loader callbacks which request different elements from the provider
  final List<ElementLoaderCallback<T>> callbacks;

  /// This is the comparator used to sort the different items returned by the callbacks
  late final Comparator<T> sortItems;

  /// If not empty, this is used to filter the model given after the provider has been requested
  final List<bool Function(T model)> extraAppFilters;

  /// Class constructor
  // We can't set the constructor as const, because sortItems is defined as `late` and the following
  // error is displayed: "Can't have a late final field in a class with a generative const
  // constructor."
  // ignore: prefer_const_constructors_in_immutables
  ElementLoaderConfig({
    required this.callbacks,
    required this.sortItems,
    this.extraAppFilters = const [],
  });

  /// This is used by derived class to fill the [callbacks] and [extraAppFilters] in derived
  /// constructor, and defines the [sortItems] in their constructor.
  ///
  /// This is useful to use methods of the derived class as [sortItems] method.
  @protected
  ElementLoaderConfig.lateConstruct()
      : callbacks = [],
        extraAppFilters = [];

  /// {@template act_http_client_manager.ElementLoaderConfig.copyWith}
  /// Copy the current state and update the properties with those given
  /// {@endtemplate}
  ElementLoaderConfig<T> copyWith({
    List<ElementLoaderCallback<T>>? callbacks,
    Comparator<T>? sortItems,
    List<bool Function(T model)>? extraAppFilters,
  }) =>
      ElementLoaderConfig(
        callbacks: callbacks ?? this.callbacks,
        sortItems: sortItems ?? this.sortItems,
        extraAppFilters: extraAppFilters ?? this.extraAppFilters,
      );

  /// Class properties
  @mustCallSuper
  @override
  List<Object?> get props => [callbacks, sortItems, extraAppFilters];
}
