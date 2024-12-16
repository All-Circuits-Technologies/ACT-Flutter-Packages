// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_enable_service_utility/src/mixin_enable_service.dart';
import 'package:act_enable_service_utility/src/ui/enable_service_request_ui_bloc.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/material.dart';

/// Display a page to ask for the user acknowledgement before redirect him to the system page for
/// enabling the service
class EnableServiceRequestUiWidget<T extends MEnableService> extends AbstractRequestUserUiWidget {
  /// Class constructor
  ///
  /// [askForEnabling] is the method used to request the user, it returns true if the user is ok
  EnableServiceRequestUiWidget({
    super.key,
    required super.acceptanceButtonBuilder,
    required VoidCallback actionIfAccepted,
    required super.childrenBuilder,
    required RequestUserCallback askForEnabling,
    super.refusalButtonBuilder,
    super.spaceBetweenChildrenAndButtons,
    super.spaceBetweenButtons,
    super.spaceAfterButtons,
    super.scaffoldBuilder,
  }) : super(
          blocBuilder: (context) => EnableServiceRequestUiBloc(
            actionIfAccepted: actionIfAccepted,
            manager: globalGetIt().get<T>(),
            requestUser: askForEnabling,
          ),
        );
}
