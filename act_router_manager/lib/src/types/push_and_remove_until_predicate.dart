// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Result of the [PushAndRemoveUntilPredicate] method
enum PushAndRemoveUntilAction {
  /// This means we can continue to pop (if there is view to pop)
  continueRemoving(isFinished: false),

  /// This means we have to push the page
  pushPage,

  /// This means we have nothing more to do (no need to push to page); this may happen if the
  /// current page is already the page we want to push.
  nothingMoreToDo;

  /// True if don't need to pop the next view
  final bool isFinished;

  /// Enum constructor
  const PushAndRemoveUntilAction({
    this.isFinished = true,
  });
}

/// This method is used with the `pushAndRemoveUntil` method, to guess if we need to pop the current
/// view or not
///
/// The [currentRoutePath] is the path of the current route
typedef PushAndRemoveUntilPredicate = PushAndRemoveUntilAction Function(String currentRoutePath);
