// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:flutter/widgets.dart';

/// This typedef is used to define a function that builds a page to display when a fatal error
/// occurs
typedef FatalErrorPageBuilder = Widget Function(Object error);

/// This typedef is used to define a handler function that is called when a fatal error page is
/// about to be displayed.
///
/// A handler may be synchronous or asynchronous; its completion is not awaited before the page is
/// shown, so it must not be relied on to finish beforehand.
typedef FatalErrorWillShowHandler = FutureOr<void> Function(Object error);
