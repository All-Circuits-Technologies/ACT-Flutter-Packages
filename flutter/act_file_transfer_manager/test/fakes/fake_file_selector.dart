// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

/// The dialog the platform displays, as a test answers for it.
class FakeFileSelector extends FileSelectorPlatform {
  /// The file the user picks, or null when they close the dialog without picking one.
  XFile? picked;

  /// True when the dialog fails to open at all.
  bool fails = false;

  /// The kinds of file the dialog has been asked to accept.
  final List<XTypeGroup> acceptedTypeGroups = [];

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    if (fails) {
      throw StateError("the dialog could not be opened");
    }

    this.acceptedTypeGroups.addAll(acceptedTypeGroups ?? const []);

    return picked;
  }
}
