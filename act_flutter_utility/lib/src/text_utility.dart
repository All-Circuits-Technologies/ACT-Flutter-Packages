// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/models/text_span_config.dart';
import 'package:flutter/material.dart';

/// Helpful model class to keep the particularity of text selection
class _TextInterval {
  /// This is the linked key to the interval
  final String? key;

  /// This is the start index of the text interval
  int startIdx;

  /// This is the end index of the text interval
  int endIdx;

  /// Default class constructor with a given length
  _TextInterval({
    required this.key,
    required this.startIdx,
    required int length,
  }) : endIdx = (startIdx + (length - 1));

  /// Class constructor with the end index
  _TextInterval.withEndIdx({
    required this.key,
    required this.startIdx,
    required this.endIdx,
  });

  /// Compare the [index] with the interval
  ///
  /// If the [index] is in the interval returns 0
  /// If the [index] is under the interval returns -1
  /// If the [index] is above the interval returns 1
  int placeInRelationToInterval(int index) {
    if (index < startIdx) {
      return -1;
    }

    if (index > endIdx) {
      return 1;
    }

    return 0;
  }

  /// Get the characters managed by the interval in the [text] given
  ///
  /// Be careful to give to this method the same [text] as the one you build the
  /// interval with
  String getIntervalText(String text) => text.substring(startIdx, endIdx + 1);
}

/// Helpful class to manage text
class TextUtility {
  /// This method allows to highlight some part of a text
  /// [text] this is the global text where we want to highlight the word
  /// [wordToHighlight].
  /// [mainTextStyle] is applied to all text and [highLightTextStyle] is only
  /// applied (above [mainTextStyle]) to the word to highlight
  static TextSpan highlightText(
    String text,
    String wordToHighlight, {
    TextStyle? mainTextStyle,
    TextStyle? highLightTextStyle,
  }) =>
      highlightTextMultipleWithConfig(text, [wordToHighlight],
          mainTextConfig: TextSpanConfig(style: mainTextStyle),
          highLightTextConfigs: (highLightTextStyle != null)
              ? {
                  wordToHighlight: TextSpanConfig(style: highLightTextStyle),
                }
              : {});

  /// This method allows to highlight some part of a text
  /// [text] this is the global text where we want to highlight the word
  /// [wordToHighlight].
  /// [mainTextConfig] is used with the text and [highLightTextConfig] is only
  /// used (above [mainTextConfig]) with the word to highlight
  static TextSpan highlightTextWithConfig(
    String text,
    String wordToHighlight, {
    TextSpanConfig? mainTextConfig,
    TextSpanConfig? highLightTextConfig,
  }) =>
      highlightTextMultipleWithConfig(text, [wordToHighlight],
          mainTextConfig: mainTextConfig,
          highLightTextConfigs: (highLightTextConfig != null)
              ? {
                  wordToHighlight: highLightTextConfig,
                }
              : {});

  /// This method allows to highlight some part of a text
  /// [text] this is the global text where we want to highlight the words
  /// [wordsToHighlight].
  ///
  /// [mainTextStyle] is applied to all text and [highLightTextStyles] are only
  /// applied (above [mainTextStyle]) to the given words to highlight
  ///
  /// The style are applied in the same order of the list [wordsToHighlight]
  /// given. Therefore if you want to highlight a part of a word, ex: "at" in a
  /// highlighted word, ex: "what", you have to set the highlight part after
  /// the word in the [wordsToHighlight] list, ex: ["what", "at"]
  static TextSpan highlightTextMultiple(
    String text,
    List<String> wordsToHighlight, {
    TextStyle? mainTextStyle,
    Map<String, TextStyle> highLightTextStyles = const {},
  }) {
    final highLightTextConfigs = <String, TextSpanConfig>{};
    for (final entry in highLightTextStyles.entries) {
      highLightTextConfigs[entry.key] = TextSpanConfig(
        style: entry.value,
      );
    }

    return highlightTextMultipleWithConfig(
      text,
      wordsToHighlight,
      highLightTextConfigs: highLightTextConfigs,
      mainTextConfig: TextSpanConfig(style: mainTextStyle),
    );
  }

  /// This method allows to highlight some part of a text
  /// [text] this is the global text where we want to highlight the words
  /// [wordsToHighlight].
  ///
  /// [mainTextConfig] is used with the text and [highLightTextConfigs] are only
  /// used (above [mainTextConfig]) with the given words to highlight
  ///
  /// The style are applied in the same order of the list [wordsToHighlight]
  /// given. Therefore if you want to highlight a part of a word, ex: "at" in a
  /// highlighted word, ex: "what", you have to set the highlight part after
  /// the word in the [wordsToHighlight] list, ex: ["what", "at"]
  static TextSpan highlightTextMultipleWithConfig(
    String text,
    List<String> wordsToHighlight, {
    TextSpanConfig? mainTextConfig,
    Map<String, TextSpanConfig> highLightTextConfigs = const {},
  }) {
    final intervals = _getIntervals(text, wordsToHighlight);
    final textSpans = <TextSpan>[];

    for (final interval in intervals) {
      final highLightTextConfig =
          (interval.key != null) ? highLightTextConfigs[interval.key] : null;
      textSpans.add(TextSpan(
        text: interval.getIntervalText(text),
        style: highLightTextConfig?.style,
        recognizer: highLightTextConfig?.recognizer,
      ));
    }

    return TextSpan(
      style: mainTextConfig?.style,
      recognizer: mainTextConfig?.recognizer,
      children: textSpans,
    );
  }

  /// This method gets the text intervals thanks to the keys given
  ///
  /// no intervals returned intersects between themselves, say otherwise: each
  /// character of the [text] given is in one, and only one, interval
  ///
  /// This methods will also creates interval for the elements not pointed by
  /// keys (they have null key)
  ///
  /// The order of the list is also the order of importance, if a key is in an
  /// another key, the last key in the list order will prevail for the interval.
  /// For instance, for the keys: ["ber"] and text: "Cumbersome" this will
  /// creates three intervals: [ cum, ber, some ]
  static List<_TextInterval> _getIntervals(String text, List<String> keys) =>
      _flatIntervals(text, keys, _findIntervals(text, keys));

  /// This methods finds all the text intervals thanks to the keys given
  ///
  /// The intervals can intersects between themselves
  /// For instance and for the keys: [ "ber"] and text: "Cumbersome" this will
  /// creates  one interval: [ "ber" ]
  static Map<String, List<_TextInterval>> _findIntervals(
    String text,
    List<String> keys,
  ) {
    final textIntervals = <String, List<_TextInterval>>{};

    for (final key in keys) {
      var idx = 0;
      final length = key.length;
      textIntervals[key] = [];

      while (idx != -1) {
        idx = text.indexOf(key, idx);

        if (idx != -1) {
          textIntervals[key]!.add(_TextInterval(
            key: key,
            startIdx: idx,
            length: length,
          ));

          // To avoid to find always the same element
          idx++;
        }
      }
    }

    return textIntervals;
  }

  /// This method removes intervals which are already dealt by the method, and
  /// there where there end index is under the current index
  static void _cleanIntervalList(int index, List<_TextInterval> intervals) {
    while (intervals.isNotEmpty) {
      if (intervals.first.endIdx >= index) {
        // Useless to go after
        break;
      }

      intervals.removeAt(0);
    }
  }

  /// This method will flatten intervals in order to avoid that some intervals
  /// intersect between themselves.
  ///
  /// This will also adds intervals for characters which aren't pointed by
  /// a key.
  ///
  /// After the call of this method, every character is in one and only one
  /// interval
  static List<_TextInterval> _flatIntervals(
    String text,
    List<String> keys,
    Map<String, List<_TextInterval>> intervalsToFlat,
  ) {
    final flattenTextIntervals = <_TextInterval>[];

    final tmpKeys = List<String>.from(keys);

    var idxWithoutChange = 0;
    String? currentKey;

    for (var index = 0; index < text.length; index++) {
      String? keyFound;

      // We begin with the last key because it's the most important element to
      // highlight
      for (var keyIdx = (tmpKeys.length - 1); keyIdx >= 0; keyIdx--) {
        final key = tmpKeys.elementAt(keyIdx);

        final tmpInter = intervalsToFlat[key]!;

        // Clean interval list in order to avoid redundant searching
        _cleanIntervalList(index, tmpInter);

        if (tmpInter.isEmpty) {
          // Remove key => it's no more useful for the search
          tmpKeys.removeAt(keyIdx);
          continue;
        }

        if (tmpInter.first.placeInRelationToInterval(index) == -1) {
          // The element is before the first key interval
          continue;
        }

        keyFound = key;
        break;
      }

      if (currentKey != keyFound) {
        if (index != 0) {
          flattenTextIntervals.add(_TextInterval.withEndIdx(
            key: currentKey,
            startIdx: idxWithoutChange,
            endIdx: index - 1,
          ));
        }

        currentKey = keyFound;
        idxWithoutChange = index;
      }

      if (index == text.length - 1) {
        // Add the last interval
        flattenTextIntervals.add(_TextInterval.withEndIdx(
          key: currentKey,
          startIdx: idxWithoutChange,
          endIdx: index,
        ));
      }
    }

    return flattenTextIntervals;
  }
}
