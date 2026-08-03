// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// What a loader asked the provider of its elements.
typedef LoaderCall = ({int offset, int limit});

/// A provider which answers the elements it was given, and records what it was asked.
class FakeProvider {
  /// The elements the provider has, in the order it gives them.
  final List<int> source;

  /// The calls the provider received, in the order it received them.
  final List<LoaderCall> calls = [];

  /// Whether the provider fails instead of answering.
  bool fails = false;

  /// Class constructor
  FakeProvider(this.source);

  /// Answers the elements which are at [offset], [limit] of them at most.
  Future<List<int>?> load({required int offset, required int limit}) async {
    calls.add((offset: offset, limit: limit));

    if (fails) {
      return null;
    }

    if (offset >= source.length) {
      return const [];
    }

    return source.sublist(offset, (offset + limit).clamp(0, source.length));
  }
}
