// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// Describes an interval by the key it carries and the characters it covers in [text].
({String? key, String value}) _describe(StringInterval interval, String text) =>
    (key: interval.key, value: interval.getIntervalString(text));

/// Describes every interval of [intervals] in [text].
List<({String? key, String value})> _describeAll(List<StringInterval> intervals, String text) =>
    intervals.map((interval) => _describe(interval, text)).toList();

void main() {
  group("StringIntervalUtility.findIntervals", () {
    test("returns one interval per occurrence of the key", () {
      final intervals = StringIntervalUtility.findIntervals("banana", ["an"]);

      expect(intervals["an"]!.map((interval) => interval.startIdx).toList(), [1, 3]);
    });

    test("finds the occurrences which overlap each other", () {
      final intervals = StringIntervalUtility.findIntervals("aaa", ["aa"]);

      expect(intervals["aa"]!.map((interval) => interval.startIdx).toList(), [0, 1]);
    });

    test("returns an empty list for a key which is not in the text", () {
      final intervals = StringIntervalUtility.findIntervals("banana", ["z"]);

      expect(intervals["z"], isEmpty);
    });

    test("ignores an empty key", () {
      expect(StringIntervalUtility.findIntervals("banana", [""]), isEmpty);
    });

    test("only processes a duplicated key once", () {
      final intervals = StringIntervalUtility.findIntervals("banana", ["an", "an"]);

      expect(intervals.keys, ["an"]);
    });
  });

  group("StringIntervalUtility.getIntervals", () {
    test("covers the whole text without any overlap", () {
      const text = "Cumbersome";

      final intervals = StringIntervalUtility.getIntervals(text, ["ber"]);

      expect(_describeAll(intervals, text), [
        (key: null, value: "Cum"),
        (key: "ber", value: "ber"),
        (key: null, value: "some"),
      ]);
    });

    test("returns a single interval without any key when no key matches", () {
      const text = "Cumbersome";

      final intervals = StringIntervalUtility.getIntervals(text, ["z"]);

      expect(_describeAll(intervals, text), [(key: null, value: text)]);
    });

    test("returns a single interval without any key when there is no key at all", () {
      const text = "Cumbersome";

      expect(_describeAll(StringIntervalUtility.getIntervals(text, []), text), [
        (key: null, value: text),
      ]);
    });

    test("starts and ends the text with a key when it matches there", () {
      const text = "abc";

      final intervals = StringIntervalUtility.getIntervals(text, ["a", "c"]);

      expect(_describeAll(intervals, text), [
        (key: "a", value: "a"),
        (key: null, value: "b"),
        (key: "c", value: "c"),
      ]);
    });

    test("splits two overlapping keys and gives the last one of the list the priority", () {
      const text = "Cumbersome";

      final intervals = StringIntervalUtility.getIntervals(text, ["mber", "ber"]);

      expect(_describeAll(intervals, text), [
        (key: null, value: "Cu"),
        (key: "mber", value: "m"),
        (key: "ber", value: "ber"),
        (key: null, value: "some"),
      ]);
    });

    test("returns an empty list for an empty text", () {
      expect(StringIntervalUtility.getIntervals("", ["a"]), isEmpty);
    });

    test("ignores the empty keys", () {
      const text = "abc";

      final intervals = StringIntervalUtility.getIntervals(text, ["", "b"]);

      expect(_describeAll(intervals, text), [
        (key: null, value: "a"),
        (key: "b", value: "b"),
        (key: null, value: "c"),
      ]);
    });
  });

  group("StringIntervalUtility.actOnInterval", () {
    test("transforms every interval and merges the results", () {
      const text = "Cumbersome";

      final result = StringIntervalUtility.actOnInterval<String, String>(
        text,
        ["ber"],
        (interval) => interval.key == null
            ? interval.getIntervalString(text)
            : interval.getIntervalString(text).toUpperCase(),
        (elements) => elements.join(),
      );

      expect(result, "CumBERsome");
    });

    test("merges an empty list when the text is empty", () {
      final result = StringIntervalUtility.actOnInterval<int, String>(
        "",
        ["a"],
        (interval) => interval.getIntervalString(""),
        (elements) => elements.length,
      );

      expect(result, 0);
    });
  });
}
