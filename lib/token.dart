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

import 'dart:convert';

import './common.dart';

class WebSocketToken {
  late final String tokenString;
  late final DateTime expiresAt;

  WebSocketToken.fromJson(String data) {
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

  @override
  String toString() {
    return "Token: '$tokenString' (expires at $expiresAt)";
  }
}
