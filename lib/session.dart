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
import './audio.dart';
import './recorder.dart' show EmblaAudioRecorder;
import './config.dart' show EmblaSessionConfig;
import './messages.dart' show GreetingsOutputMessage;

// Session state
enum EmblaSessionState { idle, starting, listening, answering, done }

class EmblaSession {
  // Current state of session object
  var state = EmblaSessionState.idle;
  var config = EmblaSessionConfig();
  final String serverURL = kDefaultServer;
  WebSocketChannel? channel;

  // Constructor
  EmblaSession(EmblaSessionConfig cfg) {
    config = cfg;
  }

  // PUBLIC METHODS

  /// Static method to preload all required assets
  static void prep() {
    AudioPlayer();
  }

  /// Start session
  void start() async {
    // Session can only be started in idle state
    if (state != EmblaSessionState.idle) {
      throw Exception("Session is not idle!");
    }

    state = EmblaSessionState.starting;

    openWebSocketConnection();
  }

  /// Stop session
  void stop() async {
    EmblaAudioRecorder().stop();

    channel?.sink.close(status.goingAway);

    state = EmblaSessionState.done;

    if (config.onDone != null) {
      config.onDone!();
    }
  }

  /// Returns true if session is active
  bool isActive() {
    return (state != EmblaSessionState.idle && state != EmblaSessionState.done);
  }

  // PRIVATE METHODS

  void error(String errMsg) {
    dlog("Error in session: $errMsg");
    stop();
    // Invoke error handler
    if (config.onError != null) {
      config.onError!(errMsg);
    }
  }

  // Open WebSocket connection to server
  void openWebSocketConnection() {
    try {
      final wsUri = Uri.parse("$serverURL$kDefaultSocketEndpoint");
      channel = WebSocketChannel.connect(wsUri);
      // Start listening for messages from server
      channel?.stream.listen(socketMessageReceived);
      // Send greetings message
      dlog("Sending initial greetings message");
      var msg = GreetingsOutputMessage().toJSON();
      channel?.sink.add(msg);
    } catch (e) {
      error("Error connecting to server: $e");
      return;
    }
  }

  void socketMessageReceived(dynamic data) {
    dlog("Received data: $data");
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
          throw ("${msg["message"]}");

        default:
          throw ("Invalid message type: $type");
      }
    } catch (e) {
      error("Error handling message: $e");
      return;
    }
  }

  void handleGreetingsMessage(Map<String, dynamic> msg) {
    dlog("Greetings message received");
    if (state != EmblaSessionState.starting) {
      throw Exception("Session is not starting!");
    }
    startListening();
    if (config.onStartListening != null) {
      config.onStartListening!();
    }
  }

  void handleASRResultMessage(Map<String, dynamic> msg) {
    dlog("ASR result message received");
    if (state != EmblaSessionState.listening) {
      throw Exception("Session is not listening!");
    }
    if (config.onSpeechTextReceived != null) {
      config.onSpeechTextReceived!(msg["text"], msg["is_final"]);
    }
  }

  void handleQueryResultMessage(Map<String, dynamic> msg) {
    dlog("Query result message received");
    if (state != EmblaSessionState.answering) {
      throw Exception("Session is not answering query!");
    }
    if (config.onQueryAnswerReceived != null) {
      config.onQueryAnswerReceived!(msg["answer"]);
    }
  }

  // Open microphone and start streaming audio to server
  void startListening() {
    state = EmblaSessionState.listening;
    EmblaAudioRecorder().start((Uint8List data) {
      channel?.sink.add(data);
    }, (String errMsg) {
      error(errMsg);
    });
  }
}
