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

import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pbenum.dart'
    show StreamingRecognizeResponse_SpeechEventType;

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
  List<String> _transcripts = [];

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
    // Session can only be started in idle state
    if (state != EmblaSessionState.idle) {
      throw Exception("Session is not idle!");
    }

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
    _speechRecognizer?.start(sttDataHandler, sttCompletionHandler, sttErrorHandler);
  }

  void sttDataHandler(dynamic data) {
    dlog("Received data: $data");

    if (state != EmblaSessionState.listening) {
      dlog('Received speech recognition results after speech recognition ended.');
      return;
    }

    // End of utterance event handling
    // TODO: It's nasty to have to import this enum from google_speech
    if (data.hasSpeechEventType()) {
      if (data.speechEventType ==
          StreamingRecognizeResponse_SpeechEventType.END_OF_SINGLE_UTTERANCE) {
        dlog('Received END_OF_SINGLE_UTTERANCE speech event.');
        stopSpeechRecognition();
      }
    }

    // Bail on empty result list
    if (data == null || data.results.length < 1) {
      dlog('Empty result from speech recognition');
      return;
    }

    var text = data.results.map((e) => e.alternatives.first.transcript).join('');
    dlog('RESULTS--------------');
    dlog(data.results);
    var first = data.results[0];
    if (first.isFinal) {
      dlog("Final result received: $text");
      for (var a in first.alternatives) {
        _transcripts.add(a.transcript.toString());
      }
      dlog("Transcripts: $_transcripts");
      stopSpeechRecognition();
    }
  }

  void sttCompletionHandler() {
    dlog("Completion handler invoked");
    state = EmblaSessionState.querying;
    // TODO: Send STT result to query server here
  }

  void sttErrorHandler(dynamic error) {
    dlog("Error: $error");
    stop();
  }

  void stopSpeechRecognition() {
    dlog('Stopping speech recognition');
    _speechRecognizer?.stop();
    _speechRecognizer = null;
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
