// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This defines the types of routes transitions that we can expect for a given page
enum RouteTransition {
  /// There is no transition to go to the next page
  none,

  /// The transition to the next page is a fade
  fade,

  /// The transition to the next page is a horizontal slide
  slide,

  /// The transition to the next page is a vertical slide
  verticalSlide;
}
