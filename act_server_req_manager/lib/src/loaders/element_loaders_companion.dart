// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_server_req_manager/src/loaders/abs_element_loader.dart';
import 'package:act_server_req_manager/src/loaders/element_loader.dart';
import 'package:act_server_req_manager/src/loaders/element_loader_config.dart';
import 'package:mutex/mutex.dart';

/// This companion helps to loads elements from different sources
class ElementLoadersCompanion<T> extends AbsElementLoader<T> {
  /// This is the loader to use for getting elements from different sources
  final List<ElementLoader<T>> _loaderModels;

  /// This is the config used to created the [ElementLoadersCompanion]
  final ElementLoaderConfig<T> config;

  /// The loading mutex
  final Mutex _loadingMutex;

  /// Private constructor
  ///
  /// The constructor will create the [ElementLoader] thanks to the given [config].callbacks
  ElementLoadersCompanion(this.config)
      : _loaderModels =
            config.callbacks.map((callback) => ElementLoader(callback: callback)).toList(),
        _loadingMutex = Mutex(),
        super(preventLoadingFewElements: false);

  /// Load elements from [loadedElements], and ask more elements from provider, if needed.
  /// The method is protected by a mutex.
  ///
  /// The method transforms the [offset] and [limit] given to only get the items not already
  /// retrieved.
  ///
  /// [limit] is the number (max limit) of elements we want to get from provider, we can get less.
  /// [offset] can be used to specify the index of the first element to retrieve from the provider.
  ///
  /// If the method returns null it means that an error occurred.
  /// If the method returns an empty list or a list with a length smaller than the [limit], it means
  /// that all the date has been loaded and no more are available.
  @override
  Future<List<T>?> load({
    required int offset,
    required int limit,
  }) =>
      _loadingMutex.protect(() async => super.load(
            offset: offset,
            limit: limit,
          ));

  /// Load the elements from provider.
  ///
  /// [limit] is the number (max limit) of elements we want to get from provider, we can get less.
  /// [offset] can be used to specify the index of the first element to retrieve from the provider.
  ///
  /// If the method returns null it means that an error occurred.
  /// If the method returns an empty list or a list with a length smaller than the [limit], it means
  /// that all the date has been loaded and no more are available.
  @override
  Future<List<T>?> loadFromProvider({
    required int offset,
    required int limit,
  }) async {
    final filteredElements = <T>[];
    final elementsRetrieved = <ElementLoader<T>, List<T>>{};
    for (final loader in _loaderModels) {
      // When the method [loadFromProvider] is called, we know that it asks for missing elements
      // between what we have retrieved and what the [load] method wants. Therefore, we can use
      // [loader.elementsSizeReallyUsed] to request the loader
      var tmpOffset = loader.elementsSizeReallyUsed;
      // We get the same [limit] number for each loaders; therefore we need to compare the
      // [filteredElements] length newly added with this loader in front of what it has already
      // been added.
      final previousFilteredElementsLength = filteredElements.length;
      while (!loader.isAllLoaded &&
          (filteredElements.length - previousFilteredElementsLength) < limit) {
        final loaderElements = await loader.load(
          offset: tmpOffset,
          limit: limit,
        );

        if (loaderElements == null) {
          appLogger().w("We failed to get the elements from the server, with offset: $offset, "
              "limit: $limit");
          return null;
        }

        if (!elementsRetrieved.containsKey(loader)) {
          elementsRetrieved[loader] = loaderElements;
        } else {
          elementsRetrieved[loader]!.addAll(loaderElements);
        }

        if (config.extraAppFilters.isNotEmpty) {
          for (final tmpElement in loaderElements) {
            var allIsOk = true;
            for (final appFilter in config.extraAppFilters) {
              if (!appFilter(tmpElement)) {
                allIsOk = false;
                break;
              }
            }

            if (allIsOk) {
              filteredElements.add(tmpElement);
            }
          }
        } else {
          filteredElements.addAll(loaderElements);
        }

        tmpOffset += loaderElements.length;
      }
    }

    filteredElements.sort(config.sortItems);

    final finalElements = ListUtility.safeSublistFromLength(filteredElements, 0, limit);
    _updateSizeReallyUsedForEachLoader<T>(finalElements, elementsRetrieved);

    return finalElements;
  }

  /// {@macro abs_server_item_loader.clearLoadedElements}
  @override
  Future<void> clearLoadedElements() => _loadingMutex.protect(() async {
        await Future.wait(_loaderModels.map((loader) => loader.clearLoadedElements()));
        return super.clearLoadedElements();
      });

  /// Call to update an element contains in the [loadedElements] list.
  ///
  /// [test] is used to say if the tested element is the one we want to update.
  /// [copyFrom] is used to return a new server item model thanks to the current one
  ///
  /// It also updates the server items of the linked [_loaderModels]
  @override
  void updatedElement(
    bool Function(T item) test,
    T Function(T current) copyFrom,
  ) {
    for (final loader in _loaderModels) {
      loader.updatedElement(test, copyFrom);
    }
    super.updatedElement(test, copyFrom);
  }

  /// Call to delete an element contains in the [loadedElements] list.
  ///
  /// [test] is used to say if the tested element is the one we want to delete.
  ///
  /// The method returns true if the method has deleted the server item or false if the element
  /// hasn't been found
  @override
  bool deletedElement(bool Function(T item) test) {
    final deletedInCompanion = super.deletedElement(test);
    for (final loader in _loaderModels) {
      if (loader.deletedElement(test) && deletedInCompanion) {
        // The element was contain in the companion and in the loader, we have to update the
        // elementsSizeReallyUsed value
        --loader.elementsSizeReallyUsed;
      }
    }

    return deletedInCompanion;
  }

  /// The method update the real size of used elements in the loaders depending of what they have
  /// returned and what the companion will use from what they have returned
  ///
  /// Because we may filter the elements retrieved from the loaders, we try to find the last used
  /// element index.
  /// We use this relative index to calculate the elementsSizeReallyUsed of the loaders.
  static void _updateSizeReallyUsedForEachLoader<T>(
    List<T> elementsWhichWillBeUsed,
    Map<ElementLoader<T>, List<T>> allTheElementsRetrieved,
  ) {
    // What is the next index the companion can request the loader from
    final newRelativeSizeUsed = <ElementLoader<T>, int>{};
    for (final finalElement in elementsWhichWillBeUsed) {
      for (final entry in allTheElementsRetrieved.entries) {
        final loader = entry.key;
        final loaderElementsRetrieved = entry.value;
        final elemIdx = loaderElementsRetrieved.indexOf(finalElement);
        if (elemIdx >= 0) {
          final nextElemIdx = elemIdx + 1;
          if (!newRelativeSizeUsed.containsKey(loader) ||
              nextElemIdx > newRelativeSizeUsed[loader]!) {
            newRelativeSizeUsed[loader] = nextElemIdx;
          }
          // Useless to iterate on all the other loaders
          break;
        }
      }
    }

    for (final relativeSize in newRelativeSizeUsed.entries) {
      relativeSize.key.elementsSizeReallyUsed += relativeSize.value;
    }
  }
}
