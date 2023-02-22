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

import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import './common.dart';
import './audio.dart';
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

  // Static method to preload all required assets
  static void prep() {
    AudioPlayer();
  }

  // Start session
  void start() async {
    // Session can only be started in idle state
    if (state != EmblaSessionState.idle) {
      throw Exception("Session is not idle!");
    }

    state = EmblaSessionState.starting;

    openWebSocketConnection();
  }

  // Open WebSocket connection to server
  void openWebSocketConnection() {
    try {
      final wsUri = Uri.parse(serverURL + "/socket");
      channel = WebSocketChannel.connect(wsUri);
      // Start listening for messages from server
      channel?.stream.listen(webSocketMessageReceived);
      // Send greetings message
      var msg = GreetingsOutputMessage().toJSON();
      channel?.sink.add(msg);
    } catch (e) {
      error("Error connecting to server: $e");
      return;
    }
  }

  void webSocketMessageReceived(dynamic data) {
    dlog("Received data: $data");
    try {
      final msg = jsonDecode(data);
      final String type = msg["type"];

      switch (type) {
        case "greetings":
          {
            handleGreetingsMessage(msg);
          }
          break;

        case "asr_result":
          {
            handleASRResultMessage(msg);
          }
          break;

        case "query_result":
          {
            handleQueryResultMessage(msg);
          }
          break;

        default:
          {
            throw ("Server error: ${msg["error"]}");
          }
      }
    } catch (e) {
      error("Error parsing message: $e");
      return;
    }
  }

  void handleGreetingsMessage(Map<String, dynamic> msg) {
    dlog("Greetings message received");
    startListening();
  }

  void handleASRResultMessage(Map<String, dynamic> msg) {
    dlog("ASR result message received");
  }

  void handleQueryResultMessage(Map<String, dynamic> msg) {
    dlog("Query result message received");
  }

  void startListening() {
    state = EmblaSessionState.listening;
  }

  void stop() async {
    AudioPlayer().stop();

    channel?.sink.close(status.goingAway);

    state = EmblaSessionState.done;

    if (config.onDone != null) {
      config.onDone!();
    }
  }

  void cancel() async {
    stop();
  }

  void error(String errMsg) {
    dlog("Error in EmblaSession: $errMsg");
    stop();

    if (config.onError != null) {
      config.onError!(errMsg);
    }
  }

  bool isActive() {
    return (state != EmblaSessionState.idle && state != EmblaSessionState.done);
  }
}
