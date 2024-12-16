// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This simple container show or hide its child.
///
/// When hidden, resulting widget can be either zero-sized or same size.
///
/// Possible future improvement: handle a deferred build of child, for cases
/// when caller want to hide a not-buildable widget and show it if valid,
/// like a non-null asset for an AssetImage.
@immutable
class HiddableWidget extends StatelessWidget {
  /// Widget to show or hide.
  final Widget child;

  /// Should [child] be visible or not.
  final bool visible;

  /// Hide method to use when [child] should be hidden.
  ///
  /// When true, [child] is embedded in a [IndexedStack], hence not unloaded
  /// from the widget tree, but hidden by another empty child of the stack.
  ///
  /// When false, child is not even inserted into the widget tree, and may be
  /// unloaded. Aan empty container is inserted instead. Keep in mind that there
  /// is still a widget in the tree (the empty container), hence putting it in
  /// a the middle of a row will make it somehow visible due to spaces around
  /// it.
  final bool keepSizeWhenHidden;

  /// Create the helper used to conditionally hide/show an already built widget.
  const HiddableWidget({
    super.key,
    required this.child,
    required this.visible,
    this.keepSizeWhenHidden = false,
  });

  @override
  Widget build(BuildContext context) => !visible && !keepSizeWhenHidden
      ? const SizedBox()
      : IndexedStack(
          alignment: AlignmentDirectional.center,
          index: visible ? 1 : 0,
          children: [
            const SizedBox(),
            child,
          ],
        );
}
