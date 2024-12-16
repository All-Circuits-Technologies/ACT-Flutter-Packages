// Copyright (c) 2020. BMS Circuits

import 'package:flutter/cupertino.dart';

class WidgetUtils {
  /// Add an '*' to the label, if needed
  static String formatInputLabelText(String labelText, bool inputRequired) {
    if (labelText == null) {
      return '*';
    }

    String labelTxt = labelText.trimRight();

    if (inputRequired && labelTxt != null && labelTxt.isNotEmpty) {
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
  ) {
    assert(0 <= percentOfSizeElem);
    assert(sizeElement != null && percentOfSizeElem != null);

    return sizeElement * (percentOfSizeElem / 100.0);
  }

  /// [getSizeWithPercent] allows to easily get the real size of an element
  /// with a factor applied on it.
  static double getSizeWithFactor(double sizeElement, double factorOfSizeElem) {
    assert(sizeElement != null && factorOfSizeElem != null);

    return sizeElement * factorOfSizeElem;
  }

  /// [getSizeElem] is useful to get the size of an element which will respect
  /// constraints.
  ///
  /// The percent is applied to the size before testing min and max size.
  /// If the size overflows the min or max value, the min or max value is
  /// returned
  static double getSizeElem(
    double sizeElem, {
    double percentToApplyOnSize: 100.0,
    double maxSizeElem,
    double minSizeElem,
  }) {
    assert(minSizeElem == null ||
        maxSizeElem == null ||
        (minSizeElem <= maxSizeElem));
    assert(sizeElem != null && percentToApplyOnSize != null);

    double realSize = getSizeWithPercent(sizeElem, percentToApplyOnSize);

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
    double percentToApplyOnParent: 100.0,
    double maxHeight,
    double minHeight,
  }) {
    assert(minHeight == null || maxHeight == null || (minHeight <= maxHeight));
    assert(context != null && percentToApplyOnParent != null);

    double parentHeight = MediaQuery.of(context).size.height;

    if (minHeight > parentHeight) {
      // The min height can't be superior to the parent size, limit the min
      // height to the parent size
      minHeight = parentHeight;
    }

    if (maxHeight > parentHeight) {
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
    double percentToApplyOnParent: 100.0,
    double maxWidth,
    double minWidth,
  }) {
    assert(minWidth == null || maxWidth == null || (minWidth <= maxWidth));
    assert(context != null && percentToApplyOnParent != null);

    double parentWidth = MediaQuery.of(context).size.width;

    if (minWidth > parentWidth) {
      // The min width can't be superior to the parent size, limit the min width
      // to the parent size
      minWidth = parentWidth;
    }

    if (maxWidth > parentWidth) {
      // The max width can't be superior to the parent size, limit the max width
      // to the parent size
      maxWidth = parentWidth;
    }

    return getSizeElem(parentWidth,
        percentToApplyOnSize: percentToApplyOnParent,
        maxSizeElem: maxWidth,
        minSizeElem: minWidth);
  }
}
