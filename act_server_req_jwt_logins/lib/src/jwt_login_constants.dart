// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library;

/// "Bearer" header value content to insert the token in request
const authBearer = "Bearer {token}";

/// "bearer" header value content to insert the token in request
const authLowBearer = "bearer {token}";

/// The token key in the bearer header value
const tokenBearerKey = "{token}";

/// "bearer" token type
const bearerTokenType = "bearer";
