// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async' show StreamSubscription;

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_themes_manager/src/blocs/act_theme_events.dart';
import 'package:act_themes_manager/src/blocs/mixin_act_themes_state.dart';
import 'package:act_themes_manager/src/managers/act_themes_manager.dart';
import 'package:act_themes_manager/src/types/mixin_act_themes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This mixin is used for the ui page to listen and update the theme of the application
///
/// This bloc uses the [ActThemesManager].
mixin MixinActThemesBloc<M extends ActThemesManager, S extends MixinActThemesState<S>>
    on BlocForMixin<S> {
  /// This is the subscription linked to the theme stream of the [ActThemesManager]
  final List<StreamSubscription> _themeSubscriptions = [];

  /// {@template act_flutter_utility.MixinActThemesBloc.themesManager}
  /// The manager of the themes of the application, used to get the current theme and update it.
  /// {@endtemplate}
  @protected
  final M themesManager = globalGetIt().get<M>();

  /// {@macro act_flutter_utility.BlocForMixin.registerMixinEvents}
  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<ThemeUpdatedEvent>(_onUpdateThemeEvent);
    on<BrightnessUpdatedEvent>(_onUpdateBrightnessEvent);
    on<AskToUpdateThemeEvent>(_onAskToUpdateThemeEvent);
    on<AskToUpdateBrightnessEvent>(_onAskToUpdateBrightnessEvent);

    _themeSubscriptions.add(themesManager.currentThemeStream.listen(_onThemeChanged));
    _themeSubscriptions.add(themesManager.brightnessStream.listen(_onBrightnessChanged));
  }

  /// This method is called when the theme of the application is updated, with the new theme.
  Future<void> _onUpdateThemeEvent(ThemeUpdatedEvent event, Emitter<S> emit) async {
    emit(state.copyToNewThemeState(currentTheme: event.updatedTheme));
  }

  /// This method is called when brightness of the application is updated, with the new brightness
  /// value.
  Future<void> _onUpdateBrightnessEvent(BrightnessUpdatedEvent event, Emitter<S> emit) async {
    emit(state.copyToNewBrightnessState(brightness: event.brightness));
  }

  /// This method is called when the user wants to update the theme of the application with the new theme.
  Future<void> _onAskToUpdateThemeEvent(AskToUpdateThemeEvent event, Emitter<S> emit) async {
    // We ask the themes manager to update the theme, which will trigger the stream and update the
    // theme of the application through the _onThemeChanged method.
    await themesManager.setCurrentTheme(newTheme: event.newTheme);
  }

  /// This method is called when the user wants to update the light mode of the application with the
  /// new light mode value.
  Future<void> _onAskToUpdateBrightnessEvent(
    AskToUpdateBrightnessEvent event,
    Emitter<S> emit,
  ) async {
    // We ask the themes manager to update the light mode value, which will trigger the stream and
    // update the light mode of the application through the _onIsLightModeChanged method.
    await themesManager.setBrightness(newBrightness: event.newBrightness);
  }

  /// Called when the theme of the application is changed
  void _onThemeChanged(MixinActThemes updatedTheme) {
    add(ThemeUpdatedEvent(updatedTheme: updatedTheme));
  }

  /// Called when the brightness mode of the application is changed
  void _onBrightnessChanged(Brightness brightness) {
    add(BrightnessUpdatedEvent(brightness: brightness));
  }

  /// {@macro act_flutter_utility.BlocForMixin.close}
  @override
  Future<void> close() async {
    await Future.wait(_themeSubscriptions.map((subscription) => subscription.cancel()));

    return super.close();
  }
}
