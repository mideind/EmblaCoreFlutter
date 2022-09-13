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

enum EmblaSessionState { idle, listen, query, answer, error, done }

class EmblaSession {
  // Properties
  // queryServer, voiceID, voiceSpeed, private, location, googleKey

  // Current state of session object
  var state = EmblaSessionState.idle;

  // Session properties
  var queryServer = kDefaultQueryServer;
  var voiceID = kDefaultSpeechSynthesisVoice;
  var voiceSpeed = kDefaultSpeechSynthesisSpeed;
  var private = false;
  var test = false;

  // Constructor
  EmblaSession(
      {queryServer = kDefaultQueryServer,
      voiceID = kDefaultSpeechSynthesisVoice,
      voiceSpeed = 1.0,
      private = false,
      location,
      googleKey}) {
    // Implement me
  }

  void start() async {
    state = EmblaSessionState.listen;
  }

  void stop() async {
    state = EmblaSessionState.idle;
  }
}
