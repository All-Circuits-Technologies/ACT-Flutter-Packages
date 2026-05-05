// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This file contains useful type definitions for the ACT Flutter packages.
///
/// It includes type definitions that are used across multiple packages, such as builders and
/// callbacks.
///
/// Most of the time, it's better to not define new type definitions, see:
/// avoid_private_typedef_functions.
///
/// However, in some cases, it can be useful to define a type definition for a function that is used
/// in multiple places, to avoid code duplication and to improve readability.
///
/// Therefore, think carefully before adding a new type definition in this file.
library;

import 'package:flutter/material.dart';

/// This is a builder function which uses the [BuildContext] to build a type.
///
/// The type can be widget, a list of widgets, or any other type that can be built using the
/// [BuildContext].
typedef GenericBuilder<T> = T Function(BuildContext context);

/// Signature for a function that creates a specific widget for a given index, e.g., in a list.
///
/// Copy from [IndexedWidgetBuilder] for a more generic version of it.
typedef IndexedGenericWidgetBuilder<T extends Widget> = T Function(BuildContext context, int index);

/// Signature for a function that creates a specific widget for a given index, e.g., in a list, but
/// may return null.
///
/// Copy from [NullableIndexedWidgetBuilder] for a more generic version of it.
typedef NullableIndexedGenericWidgetBuilder<T extends Widget> =
    T? Function(BuildContext context, int index);
