// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

/// When waiting for an answer from the device, we don't wait more than this value
/// The calling of some request may take a long time to process; therefore, this time has to be
/// adapted
const maxWaitForResponseDuration = Duration(seconds: 10);
