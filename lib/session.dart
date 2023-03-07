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

// Main session object

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import './common.dart';
import './audio.dart' show AudioPlayer;
import './recorder.dart' show EmblaAudioRecorder;
import './config.dart' show EmblaSessionConfig;
import './messages.dart' show GreetingsOutputMessage;

// Session state
enum EmblaSessionState { idle, starting, listening, answering, done }

class EmblaSession {
  // Current state of session object
  var state = EmblaSessionState.idle;
  var config = EmblaSessionConfig();
  WebSocketChannel? channel;

  /// Constructor
  EmblaSession(EmblaSessionConfig cfg) {
    config = cfg;
  }

  // PUBLIC METHODS

  /// Static method to preload all required assets
  static void prepare() {
    AudioPlayer();
  }

  /// Start session
  void start() {
    // Session can only be started in idle state
    // and cannot be restarted once it's done.
    if (state != EmblaSessionState.idle) {
      throw Exception("Session is not idle!");
    }

    state = EmblaSessionState.starting;

    openWebSocketConnection();
  }

  /// Stop session
  void stop() {
    dlog("Stopping session...");
    _stop();

    // Set state to done
    state = EmblaSessionState.done;

    // Invoke done handler
    if (config.onDone != null) {
      config.onDone!();
    }
  }

  /// Returns true if session is active
  bool isActive() {
    return (state != EmblaSessionState.idle && state != EmblaSessionState.done);
  }

  /// Returns current state of session
  EmblaSessionState currentState() {
    return state;
  }

  // PRIVATE METHODS

  void _stop() {
    // Terminate all audio recording and playback
    EmblaAudioRecorder().stop();
    AudioPlayer().stop();
    // Close WebSocket connection
    channel?.sink.close(status.goingAway);
  }

  // Terminate session with error message
  void error(String errMsg) {
    dlog("Error in session: $errMsg");
    _stop();

    // Set state to done
    state = EmblaSessionState.done;

    // Invoke error handler
    if (config.onError != null) {
      config.onError!(errMsg);
    }

    AudioPlayer().playSound("err", config.voiceID);
  }

  // Open WebSocket connection to server
  void openWebSocketConnection() {
    try {
      // Connect to server
      final wsUri = Uri.parse("${config.serverURL}$kDefaultSocketEndpoint");
      channel = WebSocketChannel.connect(wsUri);

      // Start listening for messages
      channel?.stream.listen(socketMessageReceived, onError: (e) {
        error("Error listening on WebSocket connection: $e");
      }, cancelOnError: true);

      // Create greetings message
      var greetings = GreetingsOutputMessage.fromConfig(config);

      // Send message to server
      String json = greetings.toJSON();
      dlog("Sending initial greetings message: $json");
      channel?.sink.add(json);
    } catch (e) {
      error("Error connecting to server: $e");
    }
  }

  // Handle all incoming WebSocket messages
  void socketMessageReceived(dynamic data) {
    dlog("Received message: $data");
    // Decode JSON message and handle it according to type
    try {
      final msg = jsonDecode(data);
      final String type = msg["type"];

      switch (type) {
        case "greetings":
          handleGreetingsMessage(msg);
          break;

        case "asr_result":
          handleASRResultMessage(msg);
          break;

        case "query_result":
          handleQueryResultMessage(msg);
          break;

        case "error":
          throw Exception("${msg["message"]}");

        default:
          throw Exception("Invalid message type: $type");
      }
    } catch (e) {
      error("Error handling message: $e");
      return;
    }
  }

  // Once we receive the greetings message from the server,
  // we can start listening for speech and stream the audio.
  void handleGreetingsMessage(Map<String, dynamic> msg) {
    dlog("Greetings message received. Starting listening");

    if (state != EmblaSessionState.starting) {
      throw Exception("Session is not starting!");
    }

    startListening();

    if (config.onStartListening != null) {
      config.onStartListening!();
    }
  }

  // We have received a speech recognition result from the server.
  // If it's the final result, we stop recording audio and
  // wait for the query result.
  void handleASRResultMessage(Map<String, dynamic> msg) {
    dlog("ASR result message received");

    if (state != EmblaSessionState.listening) {
      throw Exception("Session is not listening!");
    }

    String transcript = msg["transcript"];
    bool isFinal = msg["is_final"];

    if (isFinal) {
      EmblaAudioRecorder().stop();
      if (config.query) {
        state = EmblaSessionState.answering;
      }
    }

    if (config.onSpeechTextReceived != null) {
      config.onSpeechTextReceived!(transcript, isFinal);
    }

    // If this is the final ASR result and config has
    // disabled querying, we end the session.
    if (isFinal && config.query == false) {
      stop();
    }
  }

  // We have received a query result from the server.
  // We play the audio and then end the session.
  void handleQueryResultMessage(Map<String, dynamic> msg) {
    dlog("Query result message received");

    if (state != EmblaSessionState.answering) {
      throw Exception("Session is not answering query!");
    }

    Map<String, dynamic> data = msg["data"];

    // The query result did not contain an answer
    if (data["audio"] == null || data["answer"] == null) {
      String? dunnoMsg = AudioPlayer().playDunno(config.voiceID, () {
        stop();
      });

      if (config.onQueryAnswerReceived != null) {
        // This is a bit of a hack, but we need to pass
        // the dunno message text to the handler so that it
        // can be displayed in the UI.
        data["message"] = dunnoMsg;
        config.onQueryAnswerReceived!(data);
      }
      return;
    }

    if (config.onQueryAnswerReceived != null) {
      config.onQueryAnswerReceived!(data);
    }

    // Play remote audio file
    String audioURL = data["audio"];
    AudioPlayer().playURL(audioURL, (err) {
      if (err) {
        error("Error playing audio at $audioURL");
        return;
      }
      // End session after audio has finished playing
      stop();
    });
  }

  // Start recording via microphone and streaming audio to server
  void startListening() {
    state = EmblaSessionState.listening;
    EmblaAudioRecorder().start((Uint8List data) {
      channel?.sink.add(data);
    }, (String errMsg) {
      error(errMsg);
    });
  }
}
