/*
 * This file is part of the EmblaCore Flutter package
 *
 * Copyright (c) 2023 Miðeind ehf. <mideind@mideind.is>
 * Original author: Sveinbjorn Thordarson
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/// Authentication token

import 'dart:convert';

import './common.dart';

/// Authentication token object required to start a session.
class AuthenticationToken {
  late final String tokenString;
  late final DateTime expiresAt;

  AuthenticationToken.fromJson(String data) {
    try {
      final parsed = jsonDecode(data);
      tokenString = parsed['token'];
      expiresAt = DateTime.parse(parsed['expires_at']);
    } catch (e) {
      dlog("Failed to parse token JSON: $e");
      tokenString = "";
      expiresAt = DateTime.now();
    }
  }

  bool isExpired() {
    // If token expires in less than 30 seconds, consider it expired.
    return expiresAt.isAfter(DateTime.now().subtract(const Duration(seconds: 30))) == true;
  }

  @override
  String toString() {
    return "AuthToken: $tokenString (expires at $expiresAt)";
  }
}
