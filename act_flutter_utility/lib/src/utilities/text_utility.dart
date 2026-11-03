// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_flutter_utility/src/models/text_span_config.dart';
import 'package:flutter/material.dart';

/// Helpful class to manage text
class TextUtility {
  /// This method allows to highlight some part of a text
  /// [text] this is the global text where we want to highlight the word
  /// [wordToHighlight].
  /// [mainTextStyle] is applied to all text and [highLightTextStyle] is only
  /// applied (above [mainTextStyle]) to the word to highlight
  static TextSpan highlightText({
    required String text,
    required String wordToHighlight,
    TextStyle? mainTextStyle,
    TextStyle? highLightTextStyle,
  }) => highlightTextMultipleWithConfig(
    text: text,
    keys: [wordToHighlight],
    mainTextConfig: TextSpanConfig(style: mainTextStyle),
    highLightTextConfigs: (highLightTextStyle != null)
        ? {wordToHighlight: TextSpanConfig(style: highLightTextStyle)}
        : {},
  );

  /// This method allows to highlight some part of a text [text] this is the global text where we
  /// want to highlight the word [wordToHighlight].
  /// [mainTextConfig] is used with the text and [highLightTextConfig] is only used (above
  /// [mainTextConfig]) with the word to highlight
  static TextSpan highlightTextWithConfig({
    required String text,
    required String wordToHighlight,
    TextSpanConfig? mainTextConfig,
    TextSpanConfig? highLightTextConfig,
  }) => highlightTextMultipleWithConfig(
    text: text,
    keys: [wordToHighlight],
    mainTextConfig: mainTextConfig,
    highLightTextConfigs: (highLightTextConfig != null)
        ? {wordToHighlight: highLightTextConfig}
        : {},
  );

  /// This method allows to replace some part of a text [text] this is the global text where we
  /// want to replace the word [wordToReplace] with the widget [widgetToReplace].
  /// [mainTextStyle] is applied to all text and the replaced widget won't be styled even if it's
  /// in the [text] to replace.
  static TextSpan replaceTextWithWidget({
    required String text,
    required String wordToReplace,
    required Widget widgetToReplace,
    TextStyle? mainTextStyle,
  }) => highlightTextMultipleWithConfig(
    text: text,
    keys: [wordToReplace],
    mainTextConfig: TextSpanConfig(style: mainTextStyle),
    replaceTextsWithWidgets: {wordToReplace: widgetToReplace},
  );

  /// This method allows to replace some part of a text [text] this is the global text where we want to replace the word [wordToReplace] with the widget [widgetToReplace].
  /// [mainTextConfig] is used with the text and the replaced widget won't be styled even if it's
  /// in the [text] to replace.
  static TextSpan replaceTextWithWidgetAndApplyConfig({
    required String text,
    required String wordToReplace,
    required Widget widgetToReplace,
    TextSpanConfig? mainTextConfig,
  }) => highlightTextMultipleWithConfig(
    text: text,
    keys: [wordToReplace],
    mainTextConfig: mainTextConfig,
    replaceTextsWithWidgets: {wordToReplace: widgetToReplace},
  );

  /// This method allows to highlight some part of a text [text] this is the global text where we
  /// want to highlight the words [keys].
  ///
  /// [mainTextStyle] is applied to all text and [highLightTextStyles] are only applied (above
  /// [mainTextStyle]) to the given words to highlight
  ///
  /// The style are applied in the same order of the list [keys] given. Therefore if you
  /// want to highlight a part of a word, ex: "at" in a highlighted word, ex: "what", you have to
  /// set the highlight part after the word in the [keys] list, ex: ["what", "at"]
  ///
  /// The [replaceTextsWithWidgets] allows to replace some part of the text with a widget, the key
  /// of the map is the part of the text to replace and the value is the widget to put instead of
  /// this part of the text. The replacement is done before the styling, so if a part of the text is
  /// replaced by a widget, it won't be styled. The keys of the [replaceTextsWithWidgets] map must
  /// be in the [keys] list to be replaced by a widget.
  static TextSpan highlightTextMultiple({
    required String text,
    required List<String> keys,
    TextStyle? mainTextStyle,
    Map<String, TextStyle> highLightTextStyles = const {},
    Map<String, Widget> replaceTextsWithWidgets = const {},
  }) {
    final highLightTextConfigs = <String, TextSpanConfig>{};
    for (final entry in highLightTextStyles.entries) {
      highLightTextConfigs[entry.key] = TextSpanConfig(style: entry.value);
    }

    return highlightTextMultipleWithConfig(
      text: text,
      keys: keys,
      highLightTextConfigs: highLightTextConfigs,
      mainTextConfig: TextSpanConfig(style: mainTextStyle),
      replaceTextsWithWidgets: replaceTextsWithWidgets,
    );
  }

  /// The [replaceTextsWithWidgets] allows to replace some part of the text with a widget, the key
  /// of the map is the part of the text to replace and the value is the widget to put instead of
  /// this part of the text. The replacement is done before the styling, so if a part of the text is
  /// replaced by a widget, it won't be styled.
  static TextSpan replaceTextMultiple({
    required String text,
    required Map<String, Widget> replaceTextsWithWidgets,
    TextStyle? mainTextStyle,
  }) => highlightTextMultipleWithConfig(
    text: text,
    keys: replaceTextsWithWidgets.keys.toList(),
    mainTextConfig: TextSpanConfig(style: mainTextStyle),
    replaceTextsWithWidgets: replaceTextsWithWidgets,
  );

  /// This method allows to highlight some part of a text [text] this is the global text where we
  /// want to highlight the words [keys].
  ///
  /// [mainTextConfig] is used with the text and [highLightTextConfigs] are only used (above
  /// [mainTextConfig]) with the given words to highlight
  ///
  /// The style are applied in the same order of the list [keys] given. Therefore if you want to
  /// highlight a part of a word, ex: "at" in a highlighted word, ex: "what", you have to set the
  /// highlight part after the word in the [keys] list, ex: ["what", "at"]
  ///
  /// The [replaceTextsWithWidgets] allows to replace some part of the text with a widget, the key
  /// of the map is the part of the text to replace and the value is the widget to put instead of
  /// this part of the text. The replacement is done before the styling, so if a part of the text is
  /// replaced by a widget, it won't be styled. The keys of the [replaceTextsWithWidgets] map must
  /// be in the [keys] list to be replaced by a widget.
  static TextSpan highlightTextMultipleWithConfig({
    required String text,
    required List<String> keys,
    TextSpanConfig? mainTextConfig,
    Map<String, TextSpanConfig> highLightTextConfigs = const {},
    Map<String, Widget> replaceTextsWithWidgets = const {},
  }) => StringIntervalUtility.actOnInterval(
    text,
    keys,
    (interval) {
      TextSpanConfig? highLightTextConfig;
      Widget? widgetToReplace;

      final key = interval.key;
      if (key != null) {
        highLightTextConfig = highLightTextConfigs[key];
        widgetToReplace = replaceTextsWithWidgets[key];
      }

      if (widgetToReplace != null) {
        return WidgetSpan(child: widgetToReplace);
      }

      return TextSpan(
        text: interval.getIntervalString(text),
        style: highLightTextConfig?.style,
        recognizer: highLightTextConfig?.recognizer,
      );
    },
    (intervals) => TextSpan(
      style: mainTextConfig?.style,
      recognizer: mainTextConfig?.recognizer,
      children: intervals,
    ),
  );

  /// The [replaceTextsWithWidgets] allows to replace some part of the text with a widget, the key
  /// of the map is the part of the text to replace and the value is the widget to put instead of
  /// this part of the text. The replacement is done before the styling, so if a part of the text is
  /// replaced by a widget, it won't be styled.
  static TextSpan replaceTextMultipleWithWidgetAndApplyConfig({
    required String text,
    required Map<String, Widget> replaceTextsWithWidgets,
    TextSpanConfig? mainTextConfig,
  }) => highlightTextMultipleWithConfig(
    text: text,
    keys: replaceTextsWithWidgets.keys.toList(),
    mainTextConfig: mainTextConfig,
    replaceTextsWithWidgets: replaceTextsWithWidgets,
  );
}
