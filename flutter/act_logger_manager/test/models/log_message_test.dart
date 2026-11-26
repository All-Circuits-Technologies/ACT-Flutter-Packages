// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/src/models/log_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("LogMessage", () {
    test("keeps the message and the categories it is given", () {
      const message = LogMessage(message: "a message", categories: ["default", "other"]);

      expect(message.message, "a message");
      expect(message.categories, ["default", "other"]);
    });

    test("accepts a message which is not a string", () {
      const message = LogMessage(message: 3, categories: []);

      expect(message.message, 3);
    });

    test("has a value equality on the message and the categories", () {
      const message = LogMessage(message: "a message", categories: ["default"]);

      expect(message, const LogMessage(message: "a message", categories: ["default"]));
      expect(message, isNot(const LogMessage(message: "another one", categories: ["default"])));
      expect(message, isNot(const LogMessage(message: "a message", categories: ["other"])));
    });
  });
}
