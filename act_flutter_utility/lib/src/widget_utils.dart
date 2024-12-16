// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/cupertino.dart';

class WidgetUtils {
  /// Add an '*' to the label, if needed
  static String formatInputLabelText(String? labelText, bool inputRequired) {
    if (labelText == null) {
      return '*';
    }

    var labelTxt = labelText.trimRight();

    if (inputRequired && labelTxt.isNotEmpty) {
      if (labelTxt[labelTxt.length - 1] != '*') {
        labelTxt += ' *';
      }
    }

    return labelTxt;
  }

  /// [getSizeWithPercent] allows to easily get the real size of an element
  /// with a percent applied on it.
  ///
  /// [percentOfSizeElem] is a percent, so its value has to be positive
  static double getSizeWithPercent(
    double sizeElement,
    double percentOfSizeElem,
  ) =>
      sizeElement * (percentOfSizeElem / 100.0);

  /// [getSizeWithPercent] allows to easily get the real size of an element
  /// with a factor applied on it.
  static double getSizeWithFactor(double sizeElement, double factorOfSizeElem) =>
      sizeElement * factorOfSizeElem;

  /// [getSizeElem] is useful to get the size of an element which will respect
  /// constraints.
  ///
  /// The percent is applied to the size before testing min and max size.
  /// If the size overflows the min or max value, the min or max value is
  /// returned
  static double getSizeElem(
    double sizeElem, {
    double percentToApplyOnSize = 100.0,
    double? maxSizeElem,
    double? minSizeElem,
  }) {
    assert(minSizeElem == null || maxSizeElem == null || (minSizeElem <= maxSizeElem));

    final realSize = getSizeWithPercent(sizeElem, percentToApplyOnSize);

    if (minSizeElem != null && realSize < minSizeElem) {
      return minSizeElem;
    }

    if (maxSizeElem != null && realSize > maxSizeElem) {
      return maxSizeElem;
    }

    return realSize;
  }

  /// [getHeightElemFromParent] is useful to easily get a widget height based on
  /// the parent height.
  ///
  /// The percent is applied to the size before testing min and max size.
  /// If the size overflows the min or max value, the min or max value is
  /// returned
  static double getHeightElemFromParent(
    BuildContext context, {
    double percentToApplyOnParent = 100.0,
    double? maxHeight,
    double? minHeight,
  }) {
    assert(minHeight == null || maxHeight == null || (minHeight <= maxHeight));

    final parentHeight = MediaQuery.of(context).size.height;

    if (minHeight != null && minHeight > parentHeight) {
      // The min height can't be superior to the parent size, limit the min
      // height to the parent size
      minHeight = parentHeight;
    }

    if (maxHeight != null && maxHeight > parentHeight) {
      // The max height can't be superior to the parent size, limit the max
      // height to the parent size
      maxHeight = parentHeight;
    }

    return getSizeElem(parentHeight,
        percentToApplyOnSize: percentToApplyOnParent,
        maxSizeElem: maxHeight,
        minSizeElem: minHeight);
  }

  /// [getWidthElemFromParent] is useful to easily get a widget width based on
  /// the parent width.
  ///
  /// The percent is applied to the size before testing min and max size.
  /// If the size overflows the min or max value, the min or max value is
  /// returned
  static double getWidthElemFromParent(
    BuildContext context, {
    double percentToApplyOnParent = 100.0,
    double? maxWidth,
    double? minWidth,
  }) {
    assert(minWidth == null || maxWidth == null || (minWidth <= maxWidth));

    final parentWidth = MediaQuery.of(context).size.width;

    if (minWidth != null && minWidth > parentWidth) {
      // The min width can't be superior to the parent size, limit the min width
      // to the parent size
      minWidth = parentWidth;
    }

    if (maxWidth != null && maxWidth > parentWidth) {
      // The max width can't be superior to the parent size, limit the max width
      // to the parent size
      maxWidth = parentWidth;
    }

    return getSizeElem(parentWidth,
        percentToApplyOnSize: percentToApplyOnParent, maxSizeElem: maxWidth, minSizeElem: minWidth);
  }

  /// Get a widget to display an icon from the [IconData] given
  static Widget getIconDataWidget({
    required IconData icon,
    required double size,
    required Color color,
  }) =>
      Icon(
        icon,
        size: size,
        color: color,
      );

  /// Get a widget which contain an icon from an image asset, with the [iconAsset] given
  ///
  /// The image is contained in the [size] given
  static Widget getElementsIconWidget({
    required String iconAsset,
    required double size,
    Color? color,
  }) =>
      Image.asset(
        iconAsset,
        height: size,
        fit: BoxFit.contain,
        color: color,
      );

  /// Tells if a global position falls over a given widget area.
  ///
  /// Global [position] can be the one of a touch event from [Listener],
  /// like [PointerDownEvent.position], and [widgetGlobalKey] must be
  /// a [GlobalKey] identifying widget to test position with.
  ///
  /// This function does not handle overlapped widgets. That is, it can return true
  /// even if widget is masked by an overlapping widget (Stack for example).
  /// Also, it tests position against rectangular area of widget. It will return true
  /// if position is over the outer square of circle widget even if it is outside circle
  /// itself.
  static bool isGlobalPositionOverWidget(Offset position, GlobalKey widgetGlobalKey) {
    final widgetRenderBox = widgetGlobalKey.currentContext?.findRenderObject() as RenderBox;
    final widgetGlobalPosition = widgetRenderBox.localToGlobal(Offset.zero);
    final widgetSize = widgetRenderBox.size;
    final widgetGlobalRect = Rect.fromLTWH(
      widgetGlobalPosition.dx,
      widgetGlobalPosition.dy,
      widgetSize.width,
      widgetSize.height,
    );

    return widgetGlobalRect.contains(position);
  }

  /// Helpful method to add conditionally a single child scroll view between two widgets
  ///
  /// If [addCondition] is equals to true, it will add a [SingleChildScrollView] before the [child]
  static Widget addSingleChildScrollView({
    required Widget child,
    required bool addCondition,
  }) {
    if (!addCondition) {
      return child;
    }

    return SingleChildScrollView(child: child);
  }
}
