// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

/// This is the request timeout to know if we have lost internet
const requestTimeout = Duration(seconds: 15);

/// This is the default server Uri to test, in order to verify if we have internet, or not
final defaultServerUriToTest = Uri.https("www.google.com");

/// This defines a period for retesting internet connection and verify if the internet connection
/// is constant
const defaultTestPeriod = Duration(milliseconds: 300);

/// This defines the number of time we want to have a stable internet connection "status" when
/// testing the connection with a period (default value defined here: [defaultTestPeriod])
const defaultConstantValueNb = 3;

/// This is the default periodic verification enabling, used to know if we should periodically
/// verify if we have internet or not
const defaultPeriodicVerificationEnable = false;

/// This is the default periodic verification max duration to wait before checking again if we have
/// internet
const defaultPeriodicVerificationMaxDuration = Duration(seconds: 20);

/// This is the default periodic verification min duration to wait before checking again if we have
/// internet
const defaultPeriodicVerificationMinDuration = Duration(seconds: 2);
