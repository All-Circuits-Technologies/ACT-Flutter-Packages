// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_intl_ui/src/blocs/set_wanted_locale/mixin_set_wanted_locale_state.dart';
import 'package:act_intl_ui/src/blocs/set_wanted_locale/set_wanted_locale_events.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This mixin is used for the main app bloc, to get the wanted locale set by the user from the
/// [LocalesManager]
mixin MixinSetWantedLocaleBloc<S extends MixinSetWantedLocaleState<S>> on BlocForMixin<S> {
  /// Contains the subscriptions to cancel on close and linked to this mixin
  final List<StreamSubscription> _mixinSetWantedSubs = [];

  /// {@macro act_flutter_utility.BlocForMixin.registerMixinEvents}
  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<NewLocaleWantedByUserEvent>(_onNewLocaleWantedByUserEvent);
    on<CurrentLocaleUpdatedEvent>(_onCurrentLocaleUpdatedEvent);

    final localesManager = globalGetIt().get<LocalesManager>();
    _mixinSetWantedSubs.add(localesManager.currentLocaleStream.listen(_onCurrentLocaleUpdated));
    _onCurrentLocaleUpdated(localesManager.currentLocale);
  }

  /// Called when the user updated the wanted locale
  Future<void> _onNewLocaleWantedByUserEvent(
    NewLocaleWantedByUserEvent event,
    Emitter<S> emit,
  ) async {
    globalGetIt().get<LocalesManager>().wantedLocale = event.wantedLocale;
    emit(state.copyToNewLocaleWantedByUserState(wantedLocale: event.wantedLocale));
  }

  /// Called when the current locale is updated
  Future<void> _onCurrentLocaleUpdatedEvent(
    CurrentLocaleUpdatedEvent event,
    Emitter<S> emit,
  ) async {
    emit(state.copyToNewCurrentLocaleState(currentLocale: event.currentLocale));
  }

  /// Called when the current locale is updated in the [LocalesManager]
  void _onCurrentLocaleUpdated(Locale currentLocale) =>
      add(CurrentLocaleUpdatedEvent(currentLocale: currentLocale));

  /// Bloc close method
  @override
  Future<void> close() async {
    await Future.wait(_mixinSetWantedSubs.map((sub) => sub.cancel()));
    return super.close();
  }
}
