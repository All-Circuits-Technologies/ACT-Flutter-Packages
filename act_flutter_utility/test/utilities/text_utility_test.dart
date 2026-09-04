// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The style of the whole text.
const _mainStyle = TextStyle(fontSize: 12);

/// The style of the words which are highlighted.
const _highlightStyle = TextStyle(fontWeight: FontWeight.bold);

/// The parts of [span], in the order they are read.
List<InlineSpan> _partsOf(TextSpan span) => span.children ?? [];

/// The texts of the parts of [span], in the order they are read.
///
/// A part which holds a widget instead of a text reads as null.
List<String?> _textsOf(TextSpan span) =>
    _partsOf(span).map((part) => part is TextSpan ? part.text : null).toList();

void main() {
  group("TextUtility.highlightText", () {
    test("splits the text around the word it highlights", () {
      final span = TextUtility.highlightText(text: "Hello world!", wordToHighlight: "world");

      expect(_textsOf(span), ["Hello ", "world", "!"]);
    });

    test("styles only the word it highlights", () {
      final span = TextUtility.highlightText(
        text: "Hello world!",
        wordToHighlight: "world",
        mainTextStyle: _mainStyle,
        highLightTextStyle: _highlightStyle,
      );

      expect(_partsOf(span).map((part) => part.style), [null, _highlightStyle, null]);
    });

    test("styles the whole text with the main style", () {
      final span = TextUtility.highlightText(
        text: "Hello world!",
        wordToHighlight: "world",
        mainTextStyle: _mainStyle,
      );

      expect(span.style, _mainStyle);
    });

    test("keeps the text whole when the word is not in it", () {
      final span = TextUtility.highlightText(text: "Hello world!", wordToHighlight: "nothing");

      expect(_textsOf(span), ["Hello world!"]);
    });

    test("highlights every occurrence of the word", () {
      final span = TextUtility.highlightText(
        text: "a word and a word",
        wordToHighlight: "word",
        highLightTextStyle: _highlightStyle,
      );

      expect(_textsOf(span), ["a ", "word", " and a ", "word"]);
    });
  });

  group("TextUtility.highlightTextWithConfig", () {
    test("hands the recognizer of the configuration to the word it highlights", () {
      final recognizer = TapGestureRecognizer();
      addTearDown(recognizer.dispose);

      final span = TextUtility.highlightTextWithConfig(
        text: "Hello world!",
        wordToHighlight: "world",
        highLightTextConfig: TextSpanConfig(recognizer: recognizer),
      );

      final recognizers = _partsOf(span).map((part) => (part as TextSpan).recognizer);
      expect(recognizers, [null, recognizer, null]);
    });
  });

  group("TextUtility.highlightTextMultiple", () {
    test("highlights every word it is given", () {
      final span = TextUtility.highlightTextMultiple(
        text: "one and two",
        keys: ["one", "two"],
        highLightTextStyles: const {"one": _highlightStyle, "two": _mainStyle},
      );

      expect(_textsOf(span), ["one", " and ", "two"]);
      expect(_partsOf(span).map((part) => part.style), [_highlightStyle, null, _mainStyle]);
    });

    test("lets the last key win over the word which contains it", () {
      final span = TextUtility.highlightTextMultiple(
        text: "what",
        keys: ["what", "at"],
        highLightTextStyles: const {"what": _mainStyle, "at": _highlightStyle},
      );

      expect(_textsOf(span), ["wh", "at"]);
      expect(_partsOf(span).map((part) => part.style), [_mainStyle, _highlightStyle]);
    });

    test("leaves a word which is not in the text alone", () {
      final span = TextUtility.highlightTextMultiple(text: "one and two", keys: ["three"]);

      expect(_textsOf(span), ["one and two"]);
    });
  });

  group("TextUtility.replaceTextWithWidget", () {
    test("replaces the word with the widget it was given", () {
      const widget = SizedBox(width: 10);

      final span = TextUtility.replaceTextWithWidget(
        text: "Hello world!",
        wordToReplace: "world",
        widgetToReplace: widget,
      );

      expect(_textsOf(span), ["Hello ", null, "!"]);
      expect((_partsOf(span)[1] as WidgetSpan).child, widget);
    });

    test("styles the parts of the text which were not replaced", () {
      final span = TextUtility.replaceTextWithWidget(
        text: "Hello world!",
        wordToReplace: "world",
        widgetToReplace: const SizedBox(width: 10),
        mainTextStyle: _mainStyle,
      );

      expect(span.style, _mainStyle);
    });
  });

  group("TextUtility.replaceTextMultiple", () {
    test("replaces every word it is given", () {
      const first = SizedBox(width: 10);
      const second = SizedBox(width: 20);

      final span = TextUtility.replaceTextMultiple(
        text: "one and two",
        replaceTextsWithWidgets: const {"one": first, "two": second},
      );

      expect(_textsOf(span), [null, " and ", null]);
      expect((_partsOf(span).first as WidgetSpan).child, first);
      expect((_partsOf(span).last as WidgetSpan).child, second);
    });
  });

  group("TextUtility.replaceTextMultipleWithWidgetAndApplyConfig", () {
    test("styles the whole text with the configuration it was given", () {
      final span = TextUtility.replaceTextMultipleWithWidgetAndApplyConfig(
        text: "Hello world!",
        replaceTextsWithWidgets: const {"world": SizedBox(width: 10)},
        mainTextConfig: const TextSpanConfig(style: _mainStyle),
      );

      expect(span.style, _mainStyle);
      expect(_textsOf(span), ["Hello ", null, "!"]);
    });
  });
}
