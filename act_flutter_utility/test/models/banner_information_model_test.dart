// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Builds a banner of the given [type], whose weight the test moves with [priorityWeightOffset].
  BannerInformationModel aBanner({
    BannerInformationType type = BannerInformationType.info,
    int priorityWeightOffset = 0,
  }) => BannerInformationModel(
    type: type,
    text: "a message",
    foregroundColor: Colors.white,
    backgroundColor: Colors.black,
    priorityWeightOffset: priorityWeightOffset,
  );

  group("BannerInformationModel.priorityWeight", () {
    test("weighs a banner as its type does when it is not moved", () {
      expect(aBanner().priorityWeight, BannerInformationType.info.basePriorityWeight);
    });

    test("moves the weight of a banner by the offset it was built with", () {
      expect(aBanner(priorityWeightOffset: 25).priorityWeight, 225);
    });

    test("lowers the weight of a banner under the one of its type", () {
      expect(aBanner(priorityWeightOffset: -25).priorityWeight, 175);
    });

    test("weighs a moved banner above a banner of a more important type", () {
      final movedInfo = aBanner(priorityWeightOffset: 350);

      expect(
        movedInfo.priorityWeight,
        greaterThan(aBanner(type: BannerInformationType.error).priorityWeight),
      );
    });
  });
}
