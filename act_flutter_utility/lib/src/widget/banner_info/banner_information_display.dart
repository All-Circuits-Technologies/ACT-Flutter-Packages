// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math' as math;

import 'package:act_flutter_utility/src/models/banner_information_model.dart';
import 'package:act_flutter_utility/src/widget/banner_info/banner_info_bloc.dart';
import 'package:act_flutter_utility/src/widget/banner_info/banner_info_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Useful widget to display information banners above the [child] widget given
///
/// The banners are sorted from the banner with the highest priority weight to the lowest
class BannerInformationDisplay extends StatelessWidget {
  /// The child widget to display banners upper
  final Widget child;

  /// The list of banners to display above the [child]
  ///
  /// We only display [bannerNbToDisplay] elements to the list, even if the list given has a
  /// greater length.
  /// The list is sorted in the process, no need to do it yourself.
  final List<BannerInformationModel> banners;

  /// This represents the max number of banners to display in the view
  final int bannerNbToDisplay;

  /// If not null, the widget will automatically displays a banner described by this model when we
  /// loose internet.
  final BannerInformationModel? internetBannerInfoModel;

  /// This is the box shadows to use with each banners
  final List<BoxShadow>? boxShadows;

  /// This is the padding to use with the banners
  final EdgeInsetsGeometry padding;

  /// This is the minimum height of the banner
  final double minHeight;

  /// This is separator height between the banner elements
  final double separatorHeight;

  /// This is the separator between the elements in the banners
  final double bannerElementsSeparator;

  /// This is the font size
  final double fontSize;

  /// Class constructor
  const BannerInformationDisplay({
    super.key,
    this.banners = const [],
    this.bannerNbToDisplay = 1,
    this.internetBannerInfoModel,
    this.boxShadows,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 4,
    ),
    this.minHeight = 48,
    this.separatorHeight = 6,
    this.bannerElementsSeparator = 0,
    this.fontSize = 11,
    required this.child,
  }) : assert(bannerNbToDisplay >= 1, "The banner display number can't be lower than 1");

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (banners.isEmpty && internetBannerInfoModel == null) {
      return child;
    }

    return Stack(
      children: [
        child,
        BlocProvider(
          create: (context) => BannerInfoBloc(),
          child: BlocBuilder<BannerInfoBloc, BannerInfoState>(
            builder: (context, state) {
              final toDisplayBanner = state.getBanners(
                internetBannerInfoModel: internetBannerInfoModel,
                knownBanners: banners,
              );

              return ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: math.min(toDisplayBanner.length, bannerNbToDisplay),
                itemBuilder: (BuildContext context, int index) {
                  final bannerModel = toDisplayBanner[index];

                  return Container(
                    padding: padding,
                    constraints: BoxConstraints(
                      minHeight: minHeight,
                    ),
                    decoration: BoxDecoration(
                      color: bannerModel.backgroundColor,
                      boxShadow: boxShadows,
                    ),
                    child: _buildBannerContent(theme: theme, model: bannerModel),
                  );
                },
                separatorBuilder: (BuildContext context, int index) => SizedBox(
                  height: separatorHeight,
                ),
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build the banner content depending of the [model] given
  Widget _buildBannerContent({
    required BannerInformationModel model,
    required ThemeData theme,
  }) {
    final text = Text(
      model.text,
      style: theme.textTheme.bodyMedium!.copyWith(
        color: model.foregroundColor,
        fontSize: fontSize,
      ),
    );

    if (model.icon == null && model.action == null) {
      return text;
    }

    return Row(
      children: [
        if (model.icon != null) model.icon!,
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: bannerElementsSeparator),
            child: text,
          ),
        ),
        if (model.action != null) model.action!,
      ],
    );
  }
}
