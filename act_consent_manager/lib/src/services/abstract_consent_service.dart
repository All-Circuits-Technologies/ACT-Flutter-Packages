// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mutex/mutex.dart';

/// Abstract class to manage the consent of the user. Create a class in your
/// application that inherits from this class to create a service that manages
/// a specific type of consent.
abstract class AbstractConsentService<T extends MixinConsentOptions> extends AbstractService {
  /// Delay before retrying the load operation when it failed
  static const Duration _retryLoadLaterDelay = Duration(seconds: 30);

  /// This is the consent service logs helper
  final LogsHelper _logsHelper;

  /// Stream controller for the state of the consent
  final StreamController<ConsentStateEnum> _stateController;

  /// Mutex to protect the [_textWidget] from being loaded in parallel
  final Mutex _loadTextWidgetMutex;

  /// Mutex to protect the [_state] from being updated in parallel
  final Mutex _stateMutex;

  /// List of the options of the consent. Provide it with the T.values list.
  final List<T> _optionKeys;

  /// List of the observers that we need to load the consent data
  final List<ConsentObserver> _observers;

  /// List of stream subscriptions of the observers
  final List<StreamSubscription> _observersSubs;

  /// The consent data of the user loaded with [loadUserConsentData] method.
  /// It is null when loadConsentData failed to retrieve the data.
  ConsentDataModel<T>? _consentData;

  /// [Widget] to display the text of the consent in the UI. It is null when it is theorically not
  /// needed, i.e. when we are not about to ask the user to accept the consent.
  Widget? _textWidget;

  /// This is the latest version of the consent available on the server. It is null when we failed
  /// to retrieve it from the server.
  String? _latestVersion;

  /// Get the global state of the consent
  ConsentStateEnum get consentState => _guessStatus(
        latestVersion: _latestVersion,
        consentData: _consentData,
      );

  /// Get the stream that streams the state of the consent
  Stream<ConsentStateEnum> get stateStream => _stateController.stream;

  /// Get the text [Widget] of the consent if it is already loaded. You can use the method
  /// [getConsentTextWidget] to load the text if it is not already loaded.
  Widget? get textWidget => _textWidget;

  /// Class constructor
  AbstractConsentService({
    required LogsHelper logsHelper,
    required List<T> optionsList,
    required List<ConsentObserver> observers,
  })  : _logsHelper = logsHelper,
        _optionKeys = optionsList,
        _stateController = StreamController<ConsentStateEnum>.broadcast(),
        _loadTextWidgetMutex = Mutex(),
        _stateMutex = Mutex(),
        _observers = observers,
        _observersSubs = [],
        super();

  /// Nothing to initialize for the service
  @override
  Future<void> initService() async {}

  /// Try to load the consent data of the user once the view has been created.
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    await loadAllConsentInfo();
  }

  /// Try to load the consent data of the user when an observer emits a new value. You might
  /// want to override this method to add some logic when the observer emits a new value.
  @protected
  Future<void> _onObserverData(bool newValue) async {
    if (!newValue) {
      return;
    }
    await loadAllConsentInfo();
  }

  /// Get the text of the consent and convert it to a [Widget].
  /// We might fail to load the text of the consent, in this case the method
  /// will return null.
  Future<Widget?> getConsentTextWidget() async => _loadTextWidgetMutex.protect(() async {
        if (_latestVersion == null) {
          _logsHelper.e(
            "We can't load the text of the consent if we don't know what is the latest version!",
          );
          return null;
        }

        if (_textWidget == null) {
          final textResult = await loadConsentText(_latestVersion!);
          if (!textResult.isSuccess) {
            _logsHelper.w('Failed to load the text of the consent');
            return null;
          }

          _textWidget = await widgetFromConsentText(textResult.value!);
        }

        return _textWidget;
      });

  /// Get the consent options of the user.
  Future<ConsentOptionsModel<T>> getConsentOptions() => _stateMutex.protect(() async =>
      _consentData?.options ??
      ConsentOptionsModel.fromKeys(
        _optionKeys,
        ConsentStateEnum.unknown,
      ));

  /// Accept the consent.
  /// This method saves the consent data of the user with the latest version
  /// of the consent. It also updates the state of the consent.
  Future<bool> consent(ConsentOptionsModel<T> options) => _stateMutex.protect(() async {
        if (_consentData == null || _latestVersion == null) {
          _logsHelper.w("We can't consent if we don't have all the information");
          return false;
        }

        // We don't want to send data to the server if nothing changed
        if (options == _consentData!.options && _latestVersion == _consentData!.version) {
          return true;
        }

        // Merge the options with the current options since we might have some options that are not
        // specified in the new options
        final mergedOptions = _consentData!.options.merge(options: options);

        // Update the consent data and try to save it
        final newConsentData = ConsentDataModel<T>(
          version: _latestVersion,
          options: mergedOptions,
        );

        final result = await saveConsentData(newConsentData);

        // Update the state of the consent if the consent data is saved successfully
        if (!result) {
          _logsHelper.w("A problem occurred when tried to save consent data");
          return false;
        }

        _setConsentData(newConsentData);

        return true;
      });

  /// Cancel the stream subscription of the [ConsentObserver]. This method checks if the
  /// subscriptions are already canceled before trying to cancel them.
  Future<void> _cancelSubs() async {
    if (_observersSubs.isEmpty) {
      return;
    }

    for (final sub in _observersSubs) {
      await sub.cancel();
    }

    _observersSubs.clear();
  }

  /// Fetch the latest available version of the consent.
  @protected
  Future<StatusWithNotNullValueResult<ConsentLoadStatus, String>> loadLatestVersion();

  /// Fetch the text of the consent.
  @protected
  Future<StatusWithNotNullValueResult<ConsentLoadStatus, String>> loadConsentText(String version);

  /// Get (from a server or a local storage) the [ConsentDataModel] of the user.
  @protected
  Future<StatusWithNullableValueResult<ConsentLoadStatus, ConsentDataModel<T>>>
      loadUserConsentData();

  /// Save the [ConsentDataModel] of the user in a server or a local storage.
  /// Return true if the data is saved successfully, false otherwise.
  @protected
  Future<bool> saveConsentData(ConsentDataModel<T> consentData);

  /// This method creates a [Widget] from the text of the consent. The default supported text format
  /// is markdown, override this method to support other formats.
  @protected
  Future<Widget> widgetFromConsentText(String text) async => MarkdownBody(data: text);

  /// Load all the consent information required to determine the state of the consent.
  Future<void> loadAllConsentInfo() async => _stateMutex.protect(() async {
        // If we have both the _latestVersion and the _consentData, we already have all the
        // information we need.
        if (_latestVersion != null && _consentData != null) {
          return;
        }

        // Check if each observer is invalid
        for (final observer in _observers) {
          if (!observer.isValid) {
            // If one observer is invalid, we don't want to go further but we need to subscribe to
            // the observers so they can notify us when they are valid

            // If we are already subscribed to the observers, we don't need to subscribe again
            if (_observersSubs.isNotEmpty || _observers.isEmpty) {
              return;
            }

            // Subscribe to the observers
            for (final observer in _observers) {
              final sub = observer.stream.listen(_onObserverData);
              _observersSubs.add(sub);
            }

            // We stop here and we will come back later
            return;
          }
        }

        // Evaluate our loading status which default to success
        var state = ConsentLoadStatus.success;

        // Load the consent data if it is not already loaded
        if (_consentData == null) {
          final consentResult = await loadUserConsentData();

          if (consentResult.isSuccess) {
            // Here we merge the default option values with values retrieved from the server
            _setConsentData(ConsentDataModel<T>.init(
              values: _optionKeys,
            ).merge(
              other: consentResult.value,
            ));
          } else if (consentResult.canBeRetried) {
            state = ConsentLoadStatus.retryLater;
          } else {
            state = ConsentLoadStatus.failed;
          }
        }

        // If we failed to load the consent data and we know we can't get them later if we retry
        // we stop here
        if (state == ConsentLoadStatus.failed) {
          _logsHelper.e('Failed to load the consent data required to determine the '
              'state of the consent');
          // We won't try again so there is no need to keep the observers
          await _cancelSubs();
          return;
        }

        if (_latestVersion == null) {
          final latestVersionResult = await loadLatestVersion();

          if (latestVersionResult.isSuccess) {
            _setLatestVersion(latestVersionResult.value);
          } else if (latestVersionResult.canBeRetried) {
            state = ConsentLoadStatus.retryLater;
          } else {
            state = ConsentLoadStatus.failed;
          }
        }

        if (state == ConsentLoadStatus.failed) {
          _logsHelper.e('Failed to load the latest version which is required to determine the '
              'state of the consent');
          // We won't try again so there is no need to keep the observers
          await _cancelSubs();
          return;
        }

        if (state == ConsentLoadStatus.retryLater) {
          Timer(_retryLoadLaterDelay, loadAllConsentInfo);
          return;
        }

        // If we have all the information we need, we can cancel subscriptions of the observers
        await _cancelSubs();

        if (_latestVersion != _consentData!.version || !_consentData!.options.isAccepted) {
          await getConsentTextWidget();
        }
      });

  /// Change the latest version of the consent, publish the new global state if needed
  void _setLatestVersion(String? latestVersion) {
    if (latestVersion == _latestVersion) {
      return;
    }

    final previous = consentState;
    _latestVersion = latestVersion;
    _emitIfNecessary(previous: previous);
  }

  /// Change the consent data of the user, publish the new global state if needed
  void _setConsentData(ConsentDataModel<T> consentData) {
    if (consentData == _consentData) {
      return;
    }

    final previous = consentState;
    _consentData = consentData;
    _emitIfNecessary(previous: previous);
  }

  /// Publish the new global state if needed
  void _emitIfNecessary({
    required ConsentStateEnum previous,
  }) {
    final tmpState = consentState;

    if (tmpState != previous) {
      _stateController.add(tmpState);
    }
  }

  /// Guess the global state of the consent based on the latest version and the consent data
  static ConsentStateEnum _guessStatus({
    required String? latestVersion,
    required ConsentDataModel? consentData,
  }) {
    if (latestVersion == null || consentData == null) {
      return ConsentStateEnum.unknown;
    }

    if (latestVersion == consentData.version && consentData.options.isAccepted) {
      return ConsentStateEnum.accepted;
    }

    return ConsentStateEnum.notAccepted;
  }

  /// Cancel the stream subscription of the [ConsentObserver]
  @override
  Future<void> dispose() async {
    await _cancelSubs();
    await super.dispose();
  }
}
