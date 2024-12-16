// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/src/enable_service_element.dart';

/// This is the context linked to the service which may be enabled
class EnableServiceViewContext extends AbstractViewContext with MixinCompulsoryAcceptViewContext {
  /// This the global prefix key for the services which may be enabled
  static const _globalServiceKey = "enable_service";

  /// The element which may be enabled
  final EnableServiceElement element;

  /// True if the user has the obligation to enable the service to leave the page
  @override
  final bool isAcceptanceCompulsory;

  /// Class constructor
  EnableServiceViewContext({
    required this.element,
    this.isAcceptanceCompulsory = false,
  }) : super(
          uniqueKey: _createUniqueKey(
            element: element,
          ),
        );

  /// Generate an unique key for all the abstract view context
  static String _createUniqueKey({
    required EnableServiceElement element,
  }) =>
      "$_globalServiceKey:$element";
}
