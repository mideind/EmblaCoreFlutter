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

import './common.dart';
import './speech2text.dart' show SpeechRecognizer;

// Session state
enum EmblaSessionState { idle, listening, querying, answering, done }

class EmblaSession {
  // Current state of session object
  var state = EmblaSessionState.idle;

  // Configurable session properties
  String queryServer = kDefaultQueryServer;
  String voiceID = kDefaultSpeechSynthesisVoice;
  double voiceSpeed = kDefaultSpeechSynthesisSpeed;
  bool private = false;
  bool test = false;
  String apiKey = '';

  // Handlers for session events
  Function? onStartListening;
  Function? onStopListening;
  Function(List<String>)? onSpeechTextReceived;

  Function? onStartQuerying;
  Function? onStopQuerying;
  Function(dynamic)? onQueryAnswerReceived;

  Function? onStartAnswering;
  Function? onStopAnswering;

  Function? onDone;
  Function(String)? onError;

  // Private session vars
  SpeechRecognizer? _speechRecognizer;

  // Constructor
  EmblaSession(
      {String queryServer = kDefaultQueryServer,
      String voiceID = kDefaultSpeechSynthesisVoice,
      double voiceSpeed = kDefaultSpeechSynthesisSpeed,
      bool private = false,
      bool test = false,
      // Function? location, // TBD
      String apiKey = ''}) {
    this.queryServer = queryServer;
    this.voiceID = voiceID;
    this.voiceSpeed = voiceSpeed;
    this.private = private;
    this.test = test;
    this.apiKey = apiKey;
  }

  void start() async {
    state = EmblaSessionState.listening;

    if (onStartListening != null) {
      onStartListening!();
    }

    // Make sure there's an API key for the speech recognizer
    if (apiKey == '') {
      error("No API key set");
      return;
    }

    // Create and start speech recognizer
    _speechRecognizer = SpeechRecognizer(apiKey);
    _speechRecognizer?.start((data) {
      dlog(data);
    }, () {}, (dynamic) {});
  }

  void stop() async {
    _speechRecognizer?.stop();
    state = EmblaSessionState.done;
  }

  void cancel() async {
    stop();
  }

  void error(String errMsg) {
    dlog(errMsg);
    stop();
    state = EmblaSessionState.done;

    if (onError != null) {
      onError!(errMsg);
    }
  }

  bool isActive() {
    return (state != EmblaSessionState.idle && state != EmblaSessionState.done);
  }
}
