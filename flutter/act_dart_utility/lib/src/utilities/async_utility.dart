// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

/// Type for functions which takes no arguments and returns either T or Future\<T\>
///
/// This type is sometimes more interesting than standard `ValueGetter` and `AsyncValueGetter`
/// types which expresses strict T and strict Future\<T\> return values.
///
/// Note that T can be void, but you may better like [ActCallback] for void-only functions
/// since its name is clearer.
typedef ActValueGetter<T> = FutureOr<T> Function();

/// Type for void functions which takes no arguments and are either synchronous or asynchronous
///
/// This type is sometimes more interesting than standard `VoidCallback` and `AsyncCallback`
/// types which expresses strict void and strict Future\<void\> return values.
typedef ActCallback = FutureOr<void> Function();
