// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_flutter_utility/src/widget/banner_info/banner_info_event.dart';
import 'package:act_flutter_utility/src/widget/banner_info/banner_info_state.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This is the bloc of the banner information widget
class BannerInfoBloc extends Bloc<BannerInfoEvent, BannerInfoState> {
  /// Stream subscription of the no more internet stream
  late final StreamSubscription _internetSub;

  /// Class constructor
  BannerInfoBloc() : super(const BannerInfoInitState()) {
    on<BannerInfoInternetUpdateEvent>(_onInternetStateUpdated);

    _internetSub = globalGetIt()
        .get<InternetConnectivityManager>()
        .hasConnectionStream
        .listen(_onInternetUpdated);
    _onInternetUpdated();
  }

  /// Called when the [BannerInfoInternetUpdateEvent] has been emitted (after internet connection
  /// has been updated)
  Future<void> _onInternetStateUpdated(
    BannerInfoInternetUpdateEvent event,
    Emitter<BannerInfoState> emit,
  ) async {
    emit(BannerInfoInternetState(
      previousState: state,
      isInternetOk: event.isInternetOk,
    ));
  }

  /// Called when the internet connection state has been updated
  void _onInternetUpdated([bool? isInternetOk]) {
    final internetIsOk =
        isInternetOk ?? globalGetIt().get<InternetConnectivityManager>().hasConnection;

    if (state.isInternetOk != internetIsOk) {
      add(BannerInfoInternetUpdateEvent(isInternetOk: internetIsOk));
    }
  }

  @override
  Future<void> close() async {
    await _internetSub.cancel();

    return super.close();
  }
}
