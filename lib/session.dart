/*
 * This file is part of the Embla Core Flutter package
 * Copyright (c) 2022 Miðeind ehf. <mideind@mideind.is>
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

part of 'embla_core.dart';

enum EmblaSessionState { rest, listen, query, answer }

class EmblaSession {
  // Current state of session object
  var state = EmblaSessionState.rest;

  // Constructor
  EmblaSession() {}

  void start() async {
    state = EmblaSessionState.listen;
  }

  void stop() async {
    state = EmblaSessionState.rest;
  }
}
