// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_intl_ui/src/blocs/get_wanted_locale/get_wanted_locale_events.dart';
import 'package:act_intl_ui/src/blocs/get_wanted_locale/mixin_get_wanted_locale_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This mixin is used for the main app bloc, to get the wanted locale set by the user from the
/// [LocalesManager]
mixin MixinGetWantedLocaleBloc<S extends MixinGetWantedLocaleState<S>> on BlocForMixin<S> {
  /// Contains the subscriptions to cancel on close and linked to this mixin
  final List<StreamSubscription> _wantedLocalSubs = [];

  /// {@macro act_flutter_utility.BlocForMixin.registerMixinEvents}
  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<WantedLocaleUpdatedByUserEvent>(_onWantedLocaleUpdatedByUserEvent);

    final localesManager = globalGetIt().get<LocalesManager>();
    _wantedLocalSubs.add(localesManager.wantedLocaleStream.listen(_onWantedLocaleUpdated));
    _onWantedLocaleUpdated(localesManager.wantedLocale);
  }

  /// Called when the wanted locale is updated in the [LocalesManager]
  void _onWantedLocaleUpdated(Locale? newWantedLocale) =>
      add(WantedLocaleUpdatedByUserEvent(wantedLocale: newWantedLocale));

  /// Called when the user updated the wanted locale
  Future<void> _onWantedLocaleUpdatedByUserEvent(
    WantedLocaleUpdatedByUserEvent event,
    Emitter<S> emit,
  ) async {
    emit(state.copyToNewLocaleWantedByUserState(wantedLocale: event.wantedLocale));
  }

  /// Bloc close method
  @override
  Future<void> close() async {
    await Future.wait(_wantedLocalSubs.map((sub) => sub.cancel()));
    return super.close();
  }
}
