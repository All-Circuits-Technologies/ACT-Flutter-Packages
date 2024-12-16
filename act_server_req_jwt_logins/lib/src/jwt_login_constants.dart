// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

library jwt_login_constants;

/// "Bearer" header value content to insert the token in request
const authBearer = "Bearer {token}";

/// "bearer" header value content to insert the token in request
const authLowBearer = "bearer {token}";

/// The token key in the bearer header value
const tokenBearerKey = "{token}";

/// "bearer" token type
const bearerTokenType = "bearer";
