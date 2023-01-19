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

import 'package:google_speech/generated/google/cloud/speech/v1/cloud_speech.pbenum.dart'
    show StreamingRecognizeResponse_SpeechEventType;

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import './common.dart';
import './audio.dart';
import './query.dart';
import './config.dart' show EmblaConfig;
import './speech2text.dart' show SpeechRecognizer;

// Session state
enum EmblaSessionState { idle, listening, querying, answering, done }

class EmblaSession {
  // Current state of session object
  var state = EmblaSessionState.idle;
  var config = EmblaConfig();

  // Private session vars
  SpeechRecognizer? _speechRecognizer;
  final List<String> _transcripts = [];

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

    // Make sure there's an API key for the speech recognizer
    if (config.apiKey == '') {
      error("No API key set");
      return;
    }

    // Create and start speech recognizer
    _speechRecognizer = SpeechRecognizer(config.apiKey);
    _speechRecognizer?.start(sttDataHandler, sttCompletionHandler, sttErrorHandler);

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

    // End of utterance event handling
    // TODO: It's nasty to have to import this enum from google_speech
    if (data.hasSpeechEventType() &&
        data.speechEventType ==
            StreamingRecognizeResponse_SpeechEventType.END_OF_SINGLE_UTTERANCE) {
      dlog('Received END_OF_SINGLE_UTTERANCE speech event.');
      stopSpeechRecognition();
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
    var isFinal = first.isFinal;

    if (config.onSpeechTextReceived != null) {
      config.onSpeechTextReceived!([text], isFinal);
    }

    if (isFinal) {
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
    if (state == EmblaSessionState.done) {
      return;
    }
    state = EmblaSessionState.querying;
    answerQuery(_transcripts);
  }

  void sttErrorHandler(dynamic error) {
    error(" Speech to text error: $error");
  }

  void stopSpeechRecognition() {
    dlog('Stopping speech recognition');
    _speechRecognizer?.stop();
    _speechRecognizer = null;
  }

  void answerQuery(List<String> alternatives) {
    dlog("Answering query: ${alternatives.toString()}");
    // Transition to querying state
    state = EmblaSessionState.querying;

    if (config.onStartQuerying != null) {
      config.onStartQuerying!();
    }

    // Send text to query server
    QueryService.sendQuery(alternatives, handleQueryResponse,
        test: config.test,
        private: config.private,
        voiceSpeed: config.voiceSpeed,
        voiceID: config.voiceID,
        latitude: config.latitude,
        longitude: config.longitude);
  }

  // Process response from query server
  void handleQueryResponse(Map<String, dynamic>? resp) async {
    if (state != EmblaSessionState.querying) {
      dlog("Received query answer after session terminated: ${resp.toString()}");
      return;
    }

    if (config.onQueryAnswerReceived != null) {
      config.onQueryAnswerReceived!(resp);
    }

    // Received valid response to query
    if (resp != null && resp['valid'] == true && resp['error'] == null && resp['answer'] != null) {
      dlog('Received valid response to query');

      if (resp['audio'] != null) {
        // We have an audio file to play
        playAnswer(resp['audio']);
      } else {
        dlog('No audio to play, terminating session');
        stop();
      }
    }
    // Don't know
    else if (resp != null && resp['error'] != null) {
      if (config.onStartAnswering != null) {
        config.onStartAnswering!();
      }

      AudioPlayer().playDunno(() {
        dlog('Playback finished');
        stop();
      });
    }
    // Error in server response
    else {
      error("Received invalid response from query server: ${resp.toString()}");
    }
  }

  void playAnswer(String url) async {
    if (state == EmblaSessionState.done) {
      dlog("Not playing answer since session is done");
      return;
    }

    dlog('Playing $url');
    state = EmblaSessionState.answering;

    if (config.onStartAnswering != null) {
      config.onStartAnswering!();
    }

    await AudioPlayer().playURL(url, (bool err) {
      if (err == true) {
        error("Error during audio playback");
        return;
      } else {
        dlog('Playback finished');
      }

      stop();
    });
  }

  void stop() async {
    _speechRecognizer?.stop();
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

  num audioSignalStrength() {
    return _speechRecognizer?.lastSignal ?? 0.0;
  }
}
