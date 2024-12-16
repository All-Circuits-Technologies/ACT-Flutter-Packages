// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/blocs/request_user/request_user_bloc.dart';
import 'package:act_flutter_utility/src/blocs/request_user/request_user_event.dart';
import 'package:act_flutter_utility/src/blocs/request_user/request_user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This callback is used to build the request acceptance button
typedef AcceptanceButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback? onPressed,
);

/// This callback is used to build the request refusal button
typedef RefusalButtonBuilder = Widget Function(
  BuildContext context,
  bool btnEnabled,
);

/// This callback is used to build the children of the page
typedef ChildrenBuilder = List<Widget> Function(
  BuildContext context,
  bool isRequestOk,
  bool requestLoading,
);

/// This callback is used to build a scaffold to the page
typedef ScaffoldBuilder = Scaffold Function(
  BuildContext context,
  bool isRequestOk,
  bool requestLoading,
  Widget child,
);

/// This callback is used to build the bloc linked to the view
typedef RequestUiBlocBuilder<B extends RequestUserUiBloc> = B Function(BuildContext context);

/// Display an UI used to request the user for a specific action
abstract class AbstractRequestUserUiWidget<B extends RequestUserUiBloc> extends StatelessWidget {
  /// Used to build the page children
  final ChildrenBuilder childrenBuilder;

  /// If not null, this is used to wrap a built scaffold to the current widget
  final ScaffoldBuilder? scaffoldBuilder;

  /// Used to build the acceptance button
  final AcceptanceButtonBuilder acceptanceButtonBuilder;

  /// If null, it means that the user can't refuse to be requested. In that case, the acceptance
  /// button is more an acknowledgement button.
  ///
  /// If not null, used to build the refusal button
  final RefusalButtonBuilder? refusalButtonBuilder;

  /// Specify the space between the children and buttons
  final double? spaceBetweenChildrenAndButtons;

  /// Specify the space between the buttons
  final double? spaceBetweenButtons;

  /// Specify the space to add after the buttons
  final double? spaceAfterButtons;

  /// This is used to build the right bloc builder
  final RequestUiBlocBuilder<B> blocBuilder;

  /// Class constructor
  const AbstractRequestUserUiWidget({
    super.key,
    required this.acceptanceButtonBuilder,
    required this.childrenBuilder,
    required this.blocBuilder,
    this.refusalButtonBuilder,
    this.spaceBetweenChildrenAndButtons,
    this.spaceBetweenButtons,
    this.spaceAfterButtons,
    this.scaffoldBuilder,
  });

  @override
  Widget build(BuildContext context) => BlocProvider<B>(
        create: blocBuilder,
        child: BlocBuilder<B, RequestUserUiState>(
          builder: (context, state) {
            final refusalButton = _buildRefusalButton(context: context, state: state);

            return WillPopScope(
              onWillPop: () async => (refusalButtonBuilder != null || state.isOk),
              child: _wrapScaffold(
                context: context,
                state: state,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: childrenBuilder(context, state.isOk, state.loading),
                        ),
                      ),
                    ),
                    if (spaceBetweenChildrenAndButtons != null &&
                        spaceBetweenChildrenAndButtons! > 0)
                      SizedBox(height: spaceBetweenChildrenAndButtons),
                    _buildAcceptanceButton(
                      context: context,
                      state: state,
                    ),
                    if (refusalButton != null &&
                        spaceBetweenButtons != null &&
                        spaceBetweenButtons! > 0)
                      SizedBox(height: spaceBetweenButtons),
                    if (refusalButton != null) refusalButton,
                    if (spaceAfterButtons != null) SizedBox(height: spaceAfterButtons),
                  ],
                ),
              ),
            );
          },
        ),
      );

  /// Build the acceptance button
  ///
  /// If [state.loading] or [state.isOk] are equals to true, the button has to be disabled
  Widget _buildAcceptanceButton({
    required BuildContext context,
    required RequestUserUiState state,
  }) =>
      acceptanceButtonBuilder(
        context,
        state.loading || state.isOk
            ? null
            : () => BlocProvider.of<B>(context).add(const RequestUserUiAskEvent()),
      );

  /// Build the refusal button, if [refusalButtonBuilder] is not null.
  ///
  /// If [state.loading] or [state.isOk] are equals to true, the button has to be disabled
  Widget? _buildRefusalButton({
    required BuildContext context,
    required RequestUserUiState state,
  }) {
    if (refusalButtonBuilder == null) {
      return null;
    }

    return refusalButtonBuilder!(context, !state.loading && !state.isOk);
  }

  /// If needed, wrap the [child] with a scaffold built with [scaffoldBuilder]
  Widget _wrapScaffold({
    required BuildContext context,
    required RequestUserUiState state,
    required Widget child,
  }) {
    if (scaffoldBuilder == null) {
      return child;
    }

    return scaffoldBuilder!(context, state.isOk, state.loading, child);
  }
}
