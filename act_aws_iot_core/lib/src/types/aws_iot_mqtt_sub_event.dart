// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This enum is used to represent the different events that can be received from the subscription
/// process.
enum AwsIotMqttSubEvent {
  /// This event is sent when we subscribed to the topic.
  subscribed,

  /// This event is sent when we unsubscribed from the topic.
  unsubscribed,

  /// This event is sent when the subscription failed.
  subscriptionFailed,
}
