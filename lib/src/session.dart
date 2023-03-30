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

/// Main session object encapsulating Embla's core functionality

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:audio_session/audio_session.dart';

import './common.dart';
import './audio.dart' show AudioPlayer;
import './recorder.dart' show AudioRecorder;
import './config.dart' show EmblaSessionConfig;
import './messages.dart' show GreetingsOutputMessage;

void _configureAudioSession() async {
  dlog("Configuring audio session");
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration(
    avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
        AVAudioSessionCategoryOptions.defaultToSpeaker,
    // avAudioSessionMode: AVAudioSessionMode.spokenAudio,
    avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
    avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
    androidAudioAttributes: const AndroidAudioAttributes(
      contentType: AndroidAudioContentType.speech,
      flags: AndroidAudioFlags.none,
      usage: AndroidAudioUsage.voiceCommunication,
    ),
    androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    androidWillPauseWhenDucked: true,
  ));
}

// Session state
enum EmblaSessionState { idle, starting, streaming, answering, done }

/// Main session object encapsulating Embla's core functionality
class EmblaSession {
  var state = EmblaSessionState.idle; // Current state of session object
  late final EmblaSessionConfig _config;
  WebSocketChannel? _channel;

  /// Constructor, should always be called with an [EmblaSessionConfig] object as arg
  EmblaSession(EmblaSessionConfig cfg) {
    _config = cfg;
    dlog("Session created with config: ${cfg.toString()}");
  }

  // PUBLIC METHODS

  /// Static method to preload all required assets and initialize
  /// audio subsystems. This is not strictly necessary, but it will
  /// reduce the delay when starting a session for the first time.
  static void prepare() {
    // Initialize these singletons
    AudioPlayer();
    AudioRecorder();
    _configureAudioSession();
  }

  /// Start session
  void start() {
    // Session can only be started in idle state
    // and cannot be restarted once it's done.
    if (state != EmblaSessionState.idle) {
      throw Exception("Session is not idle!");
    }

    state = EmblaSessionState.starting;

    if (_config.audio) {
      AudioPlayer().playSessionStart();
    }

    _config.fetchToken().then((val) {
      if (state == EmblaSessionState.done) {
        // User canceled session before token was fetched
        return;
      }

      // Make sure we have a token
      if (_config.hasValidToken() == false) {
        _error("Missing session token!");
        return;
      }

      _openWebSocketConnection();
    }).catchError((_) {
      _error("Error fetching session token!");
    });
  }

  /// Stop session
  void stop() {
    dlog("Ending session...");
    _stop();

    // Set state to done
    state = EmblaSessionState.done;

    // Invoke done handler
    if (_config.onDone != null) {
      _config.onDone!();
    }
  }

  /// User-intitated cancellation of session
  void cancel() {
    stop();
    if (_config.audio) {
      AudioPlayer().playSessionCancel();
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
    AudioRecorder().stop();
    AudioPlayer().stop();
    // Close WebSocket connection
    _channel?.sink.close(status.goingAway);
  }

  // Terminate session with error message
  void _error(String errMsg) {
    dlog("Error in session: $errMsg");
    _stop();

    // Set state to done
    state = EmblaSessionState.done;

    // Invoke error handler
    if (_config.onError != null) {
      _config.onError!(errMsg);
    }

    AudioPlayer().playSound("err", _config.voiceID, null, _config.voiceSpeed);
  }

  // Open WebSocket connection to server
  void _openWebSocketConnection() {
    try {
      // Connect to server
      final wsUri = Uri.parse(_config.socketURL);
      _channel = WebSocketChannel.connect(wsUri);

      // Start listening for messages
      _channel?.stream.listen(_socketMessageReceived, onError: (e) {
        _error("Error listening on WebSocket connection: $e");
      }, onDone: () {
        dlog("WebSocket connection closed");
      }, cancelOnError: true);

      // Create greetings message
      final greetings = GreetingsOutputMessage.fromConfig(_config);

      // Send message to server
      final String json = greetings.toJSON();
      dlog("Sending initial greetings message: $json");
      _channel?.sink.add(json);
    } catch (e) {
      _error("Error connecting to server: $e");
    }
  }

  // Handle all incoming WebSocket messages
  void _socketMessageReceived(dynamic data) {
    dlog("Received message: $data");
    // Decode JSON message and handle it according to type
    try {
      final msg = jsonDecode(data);
      final String type = msg["type"];

      switch (type) {
        case "greetings":
          _handleGreetingsMessage(msg);
          break;

        case "asr_result":
          _handleASRResultMessage(msg);
          break;

        case "query_result":
          _handleQueryResultMessage(msg);
          break;

        case "error":
          if (msg["name"] == "timeout_error") {
            cancel();
            return;
          }
          throw Exception(msg["message"]);

        default:
          throw Exception("Invalid message type: $type");
      }
    } catch (e) {
      _error("Error handling message: $e");
      return;
    }
  }

  // Once we receive the greetings message from the server,
  // we can start listening for speech and stream the audio.
  void _handleGreetingsMessage(Map<String, dynamic> msg) {
    dlog("Greetings message received. Starting listening...");

    if (state != EmblaSessionState.starting) {
      throw Exception("Session is not starting!");
    }

    _startListening();

    if (_config.onStartListening != null) {
      _config.onStartListening!();
    }
  }

  // We have received a speech recognition result from the server.
  // If it's the final result, we stop recording audio and wait
  // for the query server response.
  void _handleASRResultMessage(Map<String, dynamic> msg) {
    dlog("ASR result message received");

    if (state != EmblaSessionState.streaming) {
      throw Exception("Session is not listening!");
    }

    final String transcript = msg["transcript"];
    final bool isFinal = msg["is_final"];

    if (isFinal) {
      dlog("Received final answer");
      AudioRecorder().stop();
      if (_config.query) {
        state = EmblaSessionState.answering;
      }
    }

    if (_config.onSpeechTextReceived != null) {
      _config.onSpeechTextReceived!(transcript, isFinal);
    }

    // If this is the final ASR result and config has
    // disabled querying, we end the session.
    if (isFinal && _config.query == false) {
      stop();
    }
  }

  // We have received a query result from the server.
  // We play the audio and then end the session.
  void _handleQueryResultMessage(Map<String, dynamic> msg) {
    dlog("Query result message received");

    if (state != EmblaSessionState.answering) {
      throw Exception("Session is not answering query!");
    }

    // if (_config.audio) {
    //   AudioPlayer().playSessionConfirm();
    // }

    try {
      final Map<String, dynamic>? data = msg["data"];
      if (data == null ||
          data["valid"] == false ||
          data["audio"] == null ||
          data["answer"] == null) {
        // Handle no answer scenario
        dlog("Query result did not contain an answer, playing dunno answer");
        String? dunnoMsg = AudioPlayer().playDunno(_config.voiceID, stop, _config.voiceSpeed);

        if (_config.onQueryAnswerReceived != null) {
          // This is a bit of a hack, but we need to pass
          // the dunno message text to the callback function
          // so that it can be displayed in the UI.
          data!["answer"] = dunnoMsg;
          _config.onQueryAnswerReceived!(data);
        }
        return;
      }

      // OK, we got an answer, notify via handler
      if (_config.onQueryAnswerReceived != null) {
        _config.onQueryAnswerReceived!(data);
      }

      // Play remote audio file
      final String audioURL = data["audio"];
      AudioPlayer().playURL(audioURL, (err) {
        if (err) {
          _error("Error playing audio at URL $audioURL");
          return;
        }
        // End session after audio answer has finished playing
        stop();
      });
    } catch (e) {
      _error("Error handling query result: $e");
      return;
    }
  }

  // Start recording via microphone and streaming audio to server
  void _startListening() {
    state = EmblaSessionState.streaming;
    AudioRecorder().start((Uint8List data) {
      _channel?.sink.add(data);
    }, (String errMsg) {
      _error(errMsg);
    });
  }

  @override
  String toString() {
    return "EmblaSession { state: $state (${(isActive() ? "active" : "inactive")}) }";
  }
}
