// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

/// This is the default value to use for the "enable crash logs" option of firebase crashlytics
const bool defaultEnableCrashLogs = false;

/// This is the default value to use for the "enable automatic crash logs" option of firebase
/// crashlytics
const bool defaultEnableAutoCrashLogs = false;

/// This is the value to use for the "enable crash logs" option of firebase crashlytics when the
/// application uses the production environment.
/// It overrides [defaultEnableCrashLogs]
const bool defaultProdEnableCrashLogs = true;

/// This is the value to use for the "enable automatic crash logs" option of firebase crashlytics
/// when the application uses the production environment.
/// It overrides [defaultEnableAutoCrashLogs]
const bool defaultProdEnableAutoCrashLogs = true;
