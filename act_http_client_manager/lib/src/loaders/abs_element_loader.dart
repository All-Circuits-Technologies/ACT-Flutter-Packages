// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/foundation.dart';

/// This callback is used to request an element from a provider.
///
/// [limit] is the number (max limit) of elements we want to get from provider, we can get less.
/// [offset] can be used to specify the index of the first element to retrieve from the provider.
///
/// If the method returns null it means that an error occurred.
/// If the method returns an empty list or a list with a length smaller than the [limit], it means
/// that all the date has been loaded and no more are available.
typedef ElementLoaderCallback<T> = Future<List<T>?> Function({
  required int offset,
  required int limit,
});

/// This is the abstract element loader, it helps to request data from provider.
///
/// The class doesn't manage empty elements in [loadedElements].
///
/// For instance, if [loadedElements] contains 6 items and if we ask 3 elements from offset 8, the
/// class will also load the elements at offset 6 and 7, to fill the gap.
abstract class AbsElementLoader<T> {
  /// This is the loaded elements
  final List<T> loadedElements;

  /// If true we always get the limit wanted (if we haven't already all the needed elements), in
  /// order to avoid to request servers for few elements.
  final bool preventLoadingFewElements;

  /// True if all the elements have been retrieved from provider and no more can be retrieved.
  bool _isAllLoaded;

  /// Get of the [_isAllLoaded] parameter
  bool get isAllLoaded => _isAllLoaded;

  /// Class constructor
  AbsElementLoader({
    this.preventLoadingFewElements = true,
  })  : loadedElements = [],
        _isAllLoaded = false;

  /// Load elements from [loadedElements], and ask more elements from provider, if needed.
  ///
  /// The method transforms the [offset] and [limit] given to only get the items not already
  /// retrieved.
  ///
  /// [limit] is the number (max limit) of elements we want to get from provider, we can get less.
  /// [offset] can be used to specify the index of the first element to retrieve from the provider.
  ///
  /// The method prepares the request before calling [loadFromProvider] to get what is needed.
  ///
  /// If the method returns null it means that an error occurred.
  /// If the method returns an empty list or a list with a length smaller than the [limit], it means
  /// that all the data have been loaded and no more are available.
  @mustCallSuper
  Future<List<T>?> load({
    required int offset,
    required int limit,
  }) async {
    var offsetToGet = offset;
    var limitToGet = limit;
    final loadedElementsLength = loadedElements.length;

    if (_isAllLoaded) {
      // Nothing more to get
      limitToGet = 0;
    } else if (offset != loadedElementsLength) {
      // We ask already retrieved elements or there is a gap (to fill) between the elements already
      // retrieved and those asked
      offsetToGet = loadedElementsLength;
      limitToGet = limit - offsetToGet + offset;
    }

    if (limitToGet > 0) {
      if (preventLoadingFewElements) {
        // If there are elements to get, we get the full limit
        limitToGet = limit;
      }

      final tmpElements = await loadFromProvider(offset: offsetToGet, limit: limitToGet);
      if (tmpElements == null) {
        appLogger().w("A problem occurred when tried to get elements with offset: $offsetToGet, "
            "limit: $limitToGet");
        return null;
      }

      if (tmpElements.length < limitToGet) {
        // We haven't retrieved all the elements asked; therefore, there are no more elements to get
        _isAllLoaded = true;
      }

      // Because:
      // - there is no gap between the asked element and the loaded elements, and
      // - we don't ask already retrieved elements,
      // we can append to the loadedElements, the elements retrieved
      loadedElements.addAll(tmpElements);
    }

    return ListUtility.safeSublistFromLength(loadedElements, offset, limit);
  }

  /// Load the elements from provider
  ///
  /// [limit] is the number (max limit) of elements we want to get from provider, we can get less.
  /// [offset] can be used to specify the index of the first element to retrieve from the provider.
  ///
  /// If the method returns null it means that an error occurred.
  /// If the method returns an empty list or a list with a length smaller than the [limit], it means
  /// that all the data have been loaded and no more are available.
  @protected
  Future<List<T>?> loadFromProvider({
    required int offset,
    required int limit,
  });

  /// {@template act_http_client_manager.abs_server_item_loader.clearLoadedElements}
  /// Remove the loaded server items from memory
  ///
  /// This is used to force the refresh of the list from the database
  /// {@endtemplate}
  @mustCallSuper
  Future<void> clearLoadedElements() async {
    loadedElements.clear();
    _isAllLoaded = false;
  }

  /// Call to update an element contains in the [loadedElements] list.
  ///
  /// [test] is used to say if the tested element is the one we want to update.
  /// [copyFrom] is used to return a new server item model thanks to the current one
  @mustCallSuper
  void updatedElement(
    bool Function(T item) test,
    T Function(T current) copyFrom,
  ) {
    final idx = loadedElements.indexWhere((element) => test(element));
    if (idx < 0) {
      // Nothing to do
      return;
    }

    loadedElements[idx] = copyFrom(loadedElements[idx]);
  }

  /// Call to delete an element contains in the [loadedElements] list.
  ///
  /// [test] is used to say if the tested element is the one we want to delete.
  ///
  /// The method returns true if the method has deleted the server item or false if the element
  /// hasn't been found
  @mustCallSuper
  bool deletedElement(bool Function(T item) test) {
    final idx = loadedElements.indexWhere((element) => test(element));
    if (idx < 0) {
      // Nothing to do
      return false;
    }

    loadedElements.removeAt(idx);
    return true;
  }
}
