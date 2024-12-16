// Copyright (c) 2020. BMS Circuits

/// Describes how we manage the route history
///
/// * If [Push] the page is added to all the others and user can go back
/// * If [ReplaceCurrent] the current page is replaced by the new one in the
///   route history. If the wanted page is the same as the current page
///   (same route and same arguments), nothing is done.
///   Therefore, the new page will have the same back page than the current one
/// * If [PopAndReplace] :
///     * If there is no previous pages: this has the same behavior than
///       [ReplaceCurrent]
///     * If there are at least one previous page this pop the current view. And then:
///         * If the newly current page is the same as the wanted one: nothing is done,
///         * If the newly current page is different than the wanted one:
///           replace the previous view by this one.
/// * If [PopAllAndPush] all the routes history is erased and the new page
///   becomes the current without history
enum RouteMovementBehavior {
  Push,
  ReplaceCurrent,
  PopAndReplace,
  PopAllAndPush,
  PopUntilAndPush
}
