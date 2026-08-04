// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_aws_iot_core/act_aws_iot_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ShadowTopicsEnum.buildTopicName", () {
    test("names the topic of a shadow of a device", () {
      expect(
        ShadowTopicsEnum.update.buildTopicName("a-thing", "a-shadow"),
        r"$aws/things/a-thing/shadow/name/a-shadow/update",
      );
    });

    test("keeps the whole relative path of a topic the server answers on", () {
      expect(
        ShadowTopicsEnum.updateAccepted.buildTopicName("a-thing", "a-shadow"),
        r"$aws/things/a-thing/shadow/name/a-shadow/update/accepted",
      );
    });

    test("names two shadows of the same device apart", () {
      expect(
        ShadowTopicsEnum.get.buildTopicName("a-thing", "a-shadow"),
        isNot(ShadowTopicsEnum.get.buildTopicName("a-thing", "another-shadow")),
      );
    });
  });

  group("ShadowTopicsEnum.buildAllTopicsName", () {
    test("names every topic of a shadow of a device", () {
      final topics = ShadowTopicsEnum.buildAllTopicsName("a-thing", "a-shadow");

      expect(topics.keys, ShadowTopicsEnum.values);
      expect(topics.values.toSet().length, ShadowTopicsEnum.values.length);
    });

    test("names each topic the way it is named on its own", () {
      final topics = ShadowTopicsEnum.buildAllTopicsName("a-thing", "a-shadow");

      for (final topic in ShadowTopicsEnum.values) {
        expect(topics[topic], topic.buildTopicName("a-thing", "a-shadow"));
      }
    });
  });
}
