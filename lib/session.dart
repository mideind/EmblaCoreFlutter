/*
 * This file is part of the EmblaCore Flutter package
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

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import './common.dart';
import './audio.dart';
import './config.dart' show EmblaConfig;

// Session state
enum EmblaSessionState { idle, listening, querying, answering, done }

class EmblaSession {
  // Current state of session object
  var state = EmblaSessionState.idle;
  var config = EmblaConfig();

  // Constructor
  EmblaSession(EmblaConfig cfg) {
    config = cfg;
  }

  // Static method to preload all required assets
  static void prep() {
    AudioPlayer();
  }

  void start() async {
    // Session can only be started in idle state
    if (state != EmblaSessionState.idle) {
      throw Exception("Session is not idle!");
    }

    state = EmblaSessionState.listening;

    if (config.onStartListening != null) {
      config.onStartListening!();
    }
  }

  void sttDataHandler(dynamic data) {
    dlog("Received data: $data");

    if (state != EmblaSessionState.listening) {
      dlog('Received speech recognition results after speech recognition ended.');
      return;
    }
  }

  void sttCompletionHandler() {
    dlog("Completion handler invoked");
    if (state == EmblaSessionState.done) {
      return;
    }
    state = EmblaSessionState.querying;
  }

  void sttErrorHandler(dynamic error) {
    error(" Speech to text error: $error");
  }

  void stopSpeechRecognition() {
    dlog('Stopping speech recognition');
  }

  void answerQuery(List<String> alternatives) {}

  void stop() async {
    AudioPlayer().stop();
    state = EmblaSessionState.done;

    if (config.onDone != null) {
      config.onDone!();
    }
  }

  void cancel() async {
    stop();
  }

  void error(String errMsg) {
    dlog("Error in session: $errMsg");
    stop();

    if (config.onError != null) {
      config.onError!(errMsg);
    }
  }

  bool isActive() {
    return (state != EmblaSessionState.idle && state != EmblaSessionState.done);
  }
}
