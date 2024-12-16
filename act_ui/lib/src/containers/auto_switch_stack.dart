// Copyright (c) 2020. BMS Circuits

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_tic_manager/act_tic_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/streams.dart';

/// This container is an [IndexedStack] which automatically loop over indexes.
///
/// In order to enforce synchronization among all [AutoSwitchStack], animation
/// is based on [TicManager] in a way that all [AutoSwitchStack] having the same
/// [slideDurationSeconds] and the same amount of children will show same index
/// at the same moment.
class AutoSwitchStack extends StatefulWidget {
  /// Per-slide duration in seconds.
  final int slideDurationSeconds;

  /// All our standard stack-related arguments are peeked fro this argument.
  final Stack stack;

  /// Create an animated slideshow of [stack] widgets, showing each slide
  /// [duration] seconds.
  ///
  /// [duration] parameter is internally truncated to closest smaller second.
  AutoSwitchStack({
    Key key,
    @required Duration duration,
    @required this.stack,
  })  : assert(duration != null),
        assert(duration.inSeconds > 0),
        assert(stack != null),
        slideDurationSeconds = duration.inSeconds,
        super(key: key);

  @override
  State createState() => _AutoSwitchStackState();
}

class _AutoSwitchStackState extends State<AutoSwitchStack> {
  /// Tic stream is used to fetch current value.
  ///
  /// Use [_ticSubscription] to get value events.
  ValueStream<int> _ticStream;

  /// Subscription to [TicManager] 1 s tic.
  StreamSubscription<int> _ticSubscription;

  /// Currently shown index.
  int _currentIndex;

  /// Recomputes wanted index and update state if necessary.
  void _refresh() {
    final int tic = _ticStream.value;

    int wantedIndex = widget.stack.children.isEmpty
        ? null
        : (tic ~/ widget.slideDurationSeconds) % widget.stack.children.length;

    if (_currentIndex != wantedIndex) {
      setState(() {
        _currentIndex = wantedIndex;
      });
    }
  }

  /// Force an initial refresh and subscribe to next tics
  @override
  void initState() {
    _ticStream = GlobalGetIt().get<TicManager>().tic1s;
    _ticSubscription = _ticStream.listen((tic) {
      _refresh();
    });

    super.initState();
  }

  /// Immediately resync when glitches are likely to occur otherwise.
  @override
  void didUpdateWidget(AutoSwitchStack oldWidget) {
    // Immediately resync when children changes in order to avoid several issues
    // such as [_currentIndex] out of new smaller list.
    // Keep in mind than [build] is not only fired when we call [_refresh], but
    // also when parent size changes, when a virtual keyboard is shown, etc.
    if (!listEquals(widget.stack.children, oldWidget.stack.children)) {
      _refresh();
    }

    super.didUpdateWidget(oldWidget);
  }

  /// Unsubscribe from tic stream.
  @override
  void dispose() {
    _ticSubscription?.cancel();
    super.dispose();
  }

  /// Renders an [IndexedStack] with [widget.stack] settings and [_currentIndex]
  /// index.
  ///
  /// If [_currentIndex] is null, show an extra empty container. This may be
  /// useful during initialization (see comment within [initState] function).
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      alignment: widget.stack.alignment,
      textDirection: widget.stack.textDirection,
      sizing: widget.stack.fit,
      index: _currentIndex ?? 0,
      children: (_currentIndex == null)
          ? <Widget>[Container(width: 0, height: 0)] + widget.stack.children
          : widget.stack.children,
    );
  }
}
