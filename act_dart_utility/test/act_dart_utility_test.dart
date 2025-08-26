// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

void main() {
  group('StringUtility', () {
    group('formatMacAddress', () {
      test('should format MAC address correctly', () {
        expect(
          StringUtility.formatMacAddress(macAddress: '0:1:20:a:bb:CC'),
          equals('00:01:20:0a:bb:CC'),
        );
      });

      test('should handle already formatted MAC address', () {
        expect(
          StringUtility.formatMacAddress(macAddress: '00:01:20:0A:BB:CC'),
          equals('00:01:20:0A:BB:CC'),
        );
      });
    });

    group('firstLetterCapital', () {
      test('should capitalize first letter', () {
        expect(
          StringUtility.firstLetterCapital(string: 'hello world'),
          equals('Hello world'),
        );
      });

      test('should handle empty string', () {
        expect(
          StringUtility.firstLetterCapital(string: ''),
          equals(''),
        );
      });

      test('should handle single character', () {
        expect(
          StringUtility.firstLetterCapital(string: 'a'),
          equals('A'),
        );
      });
    });

    group('isValidEmail', () {
      test('should validate correct email addresses', () {
        expect(StringUtility.isValidEmail('test@example.com'), isTrue);
        expect(StringUtility.isValidEmail('user@domain.org'), isTrue);
        expect(StringUtility.isValidEmail('a@b'), isTrue);
      });

      test('should reject invalid email addresses', () {
        expect(StringUtility.isValidEmail('invalid'), isFalse);
        expect(StringUtility.isValidEmail('test@'), isFalse);
        expect(StringUtility.isValidEmail('@example.com'), isFalse);
        expect(StringUtility.isValidEmail('test @example.com'), isFalse);
        expect(StringUtility.isValidEmail('test@ example.com'), isFalse);
        expect(StringUtility.isValidEmail('test@@example.com'), isFalse);
      });
    });

    group('parseStrValue', () {
      test('should parse string values', () {
        expect(StringUtility.parseStrValue<String>('hello'), equals('hello'));
        expect(StringUtility.parseStrValue<String>(null), isNull);
      });

      test('should parse int values', () {
        expect(StringUtility.parseStrValue<int>('123'), equals(123));
        expect(StringUtility.parseStrValue<int>('invalid'), isNull);
        expect(StringUtility.parseStrValue<int>(null), isNull);
      });

      test('should parse double values', () {
        expect(StringUtility.parseStrValue<double>('123.45'), equals(123.45));
        expect(StringUtility.parseStrValue<double>('invalid'), isNull);
        expect(StringUtility.parseStrValue<double>(null), isNull);
      });

      test('should parse bool values', () {
        expect(StringUtility.parseStrValue<bool>('true'), isTrue);
        expect(StringUtility.parseStrValue<bool>('false'), isFalse);
        expect(StringUtility.parseStrValue<bool>('1'), isTrue);
        expect(StringUtility.parseStrValue<bool>('0'), isFalse);
        expect(StringUtility.parseStrValue<bool>('invalid'), isNull);
        expect(StringUtility.parseStrValue<bool>(null), isNull);
      });
    });
  });

  group('BoolHelper', () {
    group('parse', () {
      test('should parse valid boolean strings', () {
        expect(BoolHelper.parse('true'), isTrue);
        expect(BoolHelper.parse('TRUE'), isTrue);
        expect(BoolHelper.parse('True'), isTrue);
        expect(BoolHelper.parse('1'), isTrue);
        
        expect(BoolHelper.parse('false'), isFalse);
        expect(BoolHelper.parse('FALSE'), isFalse);
        expect(BoolHelper.parse('False'), isFalse);
        expect(BoolHelper.parse('0'), isFalse);
      });

      test('should throw FormatException for invalid strings', () {
        expect(() => BoolHelper.parse('invalid'), throwsFormatException);
        expect(() => BoolHelper.parse('yes'), throwsFormatException);
        expect(() => BoolHelper.parse('no'), throwsFormatException);
        expect(() => BoolHelper.parse(''), throwsFormatException);
      });
    });

    group('tryParse', () {
      test('should parse valid boolean strings', () {
        expect(BoolHelper.tryParse('true'), isTrue);
        expect(BoolHelper.tryParse('TRUE'), isTrue);
        expect(BoolHelper.tryParse('1'), isTrue);
        expect(BoolHelper.tryParse('false'), isFalse);
        expect(BoolHelper.tryParse('FALSE'), isFalse);
        expect(BoolHelper.tryParse('0'), isFalse);
      });

      test('should return null for invalid strings', () {
        expect(BoolHelper.tryParse('invalid'), isNull);
        expect(BoolHelper.tryParse('yes'), isNull);
        expect(BoolHelper.tryParse('no'), isNull);
        expect(BoolHelper.tryParse(''), isNull);
      });
    });
  });
}
