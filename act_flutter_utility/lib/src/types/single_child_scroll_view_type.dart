// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This enum describes possible scrollable options for a page
///
/// See also [OptionalSingleChildScrollView] widget which is the effective end user of this enum.
enum SingleChildScrollViewType {
  /// Pages do not need any scroll capabilities
  ///
  /// Note that if page content does not fit in phone screen, bottom will not be accessible.
  /// In most cases you likely want to use [scroll] instead since users may have small screens
  /// and/or large fonts and the like.
  noScroll,

  /// Pages should scroll if its content do not entirely fit on screen.
  ///
  /// Use this option if the content of your page has no expandable widgets, that is no Spacers,
  /// no Expanded, no MainAxisSize.max Columns and the like in which case more CPU intensive
  /// [expandedScroll] is needed.
  scroll,

  /// Pages should be scrollable despite an expandable content
  ///
  /// This is the option you typically want to use in form pages featuring a bottom submit button,
  /// likely prepended by a spacer. If form is small, page will not be scrollable and button will
  /// be located in the bottom of the page; and if form is longer then spacer will reduce to its
  /// minimum, button will be placed just under the form in the scrollable view.
  ///
  /// Please note that [expandedScroll] is a more CPU costly solution.
  /// Only use it if you can't do anything else.
  expandedScroll,
}
