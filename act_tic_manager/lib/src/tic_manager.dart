// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';

/// Builder for creating the TicManager
class TicBuilder extends ManagerBuilder<TicManager> {
  /// A factory to create a manager instance
  TicBuilder() : super(TicManager.new);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// Tic manager helps synchronizing UI updates.
///
/// This manager creates timer-based streams used by widgets to synchronize
/// their animations. Those streams generates incremental numbers from 0 to
/// [countersMaxValue] (wrapping to zero on overflow).
class TicManager extends AbstractManager {
  /// Tic counters wrap on signed 32bit values.
  ///
  /// Please keep it 2^x so we masks can be used easily.
  static const countersMaxValue = 0xffffffff;

  /// Main 500ms clock generator.
  ///
  /// All tic derive from this generator, or from a tic derived from it.
  /// Unfortunately, since I started using rx in this class, Stream.periodic
  /// somehow stopped working hence I manually generate this tic, in a less
  /// efficient way than Dart Stream.periodic which stops generating numbers
  /// when nobody listen.
  final TicGenerator _ticGen500ms = TicGenerator(const Duration(milliseconds: 500));

  /// This tic generates an incremental number at 500 milliseconds rate.
  ///
  /// Note that [Stream.periodic] internals increments its integer counter
  /// without taking are of negative wrapping. This is the reason why
  /// we mask it so we return a unsigned 32-bits wrapping counter instead
  /// of [Stream.periodic] signed 64-bits wrapping counter. Generated numbers
  /// are wrapped from 0 to [countersMaxValue].
  ValueStream<int> get tic500ms => _ticGen500ms.stream;

  /// This modulo is used to generate [tic1s] in sync with [tic500ms].
  late TicModulo _ticGen1s;

  /// This tic generates an incremental number at 1 second rate.
  ///
  /// Generated numbers are wrapped from 0 to [countersMaxValue].
  ValueStream<int> get tic1s => _ticGen1s.stream;

  /// Initialize all tics.
  ///
  /// Actually start them all too. We may want to handle idle cases one day.
  TicManager() : super() {
    _ticGen1s = TicModulo(tic500ms, 2);
  }

  /// Init the manager
  @override
  Future<void> initManager() async {}
}

/// This class generate a periodic rx value stream at wanted rate.
///
/// Value is always positive or zero and wraps at [TicManager.countersMaxValue].
class TicGenerator {
  /// Current value is incremented and announced each time [timer] fires.
  ///
  /// This value is always positive and wraps at [TicManager.countersMaxValue].
  int _counter = 0;

  /// This stream controller contains the value stream.
  final _streamController = BehaviorSubject<int>.seeded(0);

  /// This is the stream you want to listen to.
  ValueStream<int> get stream => _streamController.stream;

  /// Create a main tic which produce incremental numbers at given [interval].
  TicGenerator(Duration interval)
      : assert(!interval.isNegative, "The interval duration can't be negative"),
        assert(interval != Duration.zero, "The interval duration can't be equal to zero") {
    Timer.periodic(interval, (timer) {
      _counter++;
      _counter &= TicManager.countersMaxValue;
      _streamController.add(_counter);
    });
  }
}

/// This class generates a slow tick stream based on a [source] tic stream.
///
/// Generated tic is synchronized with [source] so it generates an event each
/// time [source] generates a counter factor of [modulo].
class TicModulo {
  /// The tic stream source which si divided by [modulo].
  final Stream<int> source;

  /// How many [source] events should be received before generating our event.
  final int modulo;

  /// Stream controller used to generate our events.
  final _streamController = BehaviorSubject<int>();

  /// Internal counter.
  int _counter = 0;

  /// Return the stream animated by this generator.
  ///
  /// This stream delivers incremental counter on a [source] rate / [modulo].
  ValueStream<int> get stream => _streamController.stream;

  /// Create a tick modulo.
  ///
  /// Resulting [stream] will generate one tic each [modulo] ticks of [source].
  TicModulo(this.source, this.modulo)
      : assert(modulo > 1,
            "The module as to be greater than one in order to be really relevant here") {
    source.listen((counter) {
      if ((counter % modulo) == 0) {
        _counter++;
        _counter &= TicManager.countersMaxValue;
        _streamController.add(_counter);
      }
    });
  }
}
