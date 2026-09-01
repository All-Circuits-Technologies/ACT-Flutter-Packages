// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/widgets.dart';

/// This typedef is used to define a function that builds a page to display when a fatal error
/// occurs
typedef FatalErrorPageBuilder = Widget Function(Object error);

/// This typedef is used to define a handler function that is called when a fatal error page is
/// about to be displayed.
typedef FatalErrorWillShowHandler = void Function(Object error);
