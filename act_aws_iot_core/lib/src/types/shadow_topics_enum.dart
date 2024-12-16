// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// This enum contains all the shadow topics that can be used to interact with an Aws iot core
/// shadow.
enum ShadowTopicsEnum {
  /// This topic is used to update the shadow
  update('update'),

  /// This topic is used by the aws shadow service to notify that the shadow has been updated
  updateAccepted('update/accepted'),

  /// This topic is used by the aws shadow service to notify that the shadow update has been rejected
  updateRejected('update/rejected'),

  /// This topic is used to get the shadow
  get('get'),

  /// This topic is used by the aws shadow service to notify that the shadow has been retrieved
  getAccepted('get/accepted'),

  /// This topic is used by the aws shadow service to notify that the shadow retrieval has been
  /// rejected
  getRejected('get/rejected');

  /// This key is used to replace the thing name in the topic. See [buildTopicName]
  static const _thingNameKey = 'thingName';

  /// This key is used to replace the shadow name in the topic. See [buildTopicName]
  static const _shadowNameKey = 'shadowName';

  /// This key is used to replace the relative path in the topic. See [buildTopicName]
  static const _relativePathKey = 'relativePath';

  /// These are the segments that are used to build the full topic name
  static const List<String> _segments = [
    r'$aws',
    'things',
    _thingNameKey,
    'shadow',
    'name',
    _shadowNameKey,
    _relativePathKey,
  ];

  /// This relative path is specific to each [ShadowTopicsEnum] and is used to build the full topic
  final String relativePath;

  /// Class constructor
  const ShadowTopicsEnum(this.relativePath);

  /// This method builds the full topic named based on a given [thingName] and [shadowName]
  String buildTopicName(
    String thingName,
    String shadowName,
  ) =>
      UriUtility.formatPathFromSegments(
        segments: _segments,
        parameters: {
          _thingNameKey: thingName,
          _shadowNameKey: shadowName,
          _relativePathKey: relativePath,
        },
      );

  /// This methods builds all the topics names based on a given [thingName] and [shadowName]
  static Map<ShadowTopicsEnum, String> buildAllTopicsName(
    String thingName,
    String shadowName,
  ) {
    final map = <ShadowTopicsEnum, String>{};

    for (final topic in ShadowTopicsEnum.values) {
      map[topic] = topic.buildTopicName(thingName, shadowName);
    }

    return map;
  }
}
