// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';

/// Add specific methods to [AbstractViewBuilder] when using enable service utility
mixin MixinEnableServiceViewBuilder on AbstractViewBuilder {
  /// This allows to register a page to display when a service enabling is asked to user
  void onEnablePage({
    required MixinRoute route,
    required EnableServiceElement element,
  }) =>
      onContextualPage(
        context: EnableServiceViewContext(
          element: element,
        ),
        route: route,
      );
}
