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

/// Embla session configuration

import 'package:http/http.dart' show get, Response;

import './token.dart';
import './common.dart';

/// EmblaSession configuration object
class EmblaSessionConfig {
  // Constructor
  EmblaSessionConfig({String server = kDefaultServer}) {
    dlog("Creating EmblaSessionConfig object");
    ratatoskurServer = server;
    _tokenURL = "$server$kTokenEndpoint";

    String webSocketURL = server;
    if (webSocketURL.startsWith("https")) {
      // We're using SSL, so we need to use wss://
      webSocketURL = webSocketURL.replaceFirst("https", "wss");
    } else {
      webSocketURL = webSocketURL.replaceFirst("http", "ws");
    }
    dlog("Using socket URL $webSocketURL");
    socketURL = "$webSocketURL$kSocketEndpoint";
  }

  /// Ratatoskur server URL.
  late String ratatoskurServer = kDefaultServer;

  /// URL to API that provides authentication token for WebSocket communication.
  late String _tokenURL;

  /// WebSocket URL for the Ratatoskur ASR + Query + TTS pipeline.
  late String socketURL;

  /// Server API key.
  String? apiKey;

  /// Speech-to-text language (e.g. `is-IS`, `en-US`).
  String language = kSpeechToTextLanguage;

  /// Override default ASR engine.
  String? engine;

  /// Voice ID to use when synthesizing speech. Default is 'Gudrun'.
  String voiceID = kDefaultSpeechSynthesisVoice;

  /// Voice speed to use when synthesizing speech. Default is `1.0`.
  double voiceSpeed = kDefaultSpeechSynthesisSpeed;

  /// Don't send client info to server. Default is `false`.
  bool privateMode = false;

  /// Client ID should be set by client app.
  /// Ideally, a unique app-specific client ID should
  /// be provided via e.g. the `platform_device_id` package.
  String? clientID;

  /// Client type string (e.g. `ios`, `android`).
  /// Third-party clients should use their own name
  /// here, e.g. `myappname_ios`, `myappname_android`.
  String? clientType;

  /// Client version string (e.g. `1.3.1`).
  /// Can be fetched via e.g. the `package_info_plus` package.
  String? clientVersion;

  /// Whether Ratatoskur should send ASR text to the query server
  /// and subsequently forward the query response to the client.
  /// Defaults to `true`.
  bool query = true;

  /// Whether Ratatoskur should speech synthesize query server answer
  /// and subsequently forward the audio to the client.
  /// Defaults to `true`.
  bool tts = true;

  /// Query server URL. Defaults to [kDefaultQueryServer].
  String queryServer = kDefaultQueryServer;

  /// Whether to play session UI sounds.
  bool audio = true;

  static AuthenticationToken? _token;

  /// WebSocket token for authenticated
  /// communication with the server.
  get token {
    if (_token == null) {
      return "";
    }
    return _token?.tokenString;
  }

  bool hasValidToken() {
    final t = _token;
    return (t != null && t.tokenString.isNotEmpty && t.isExpired() == false);
  }

  // Fetch token for WebSocket communication if needed
  Future<void> fetchToken() async {
    if (_token != null && _token?.isExpired() == false) {
      dlog("Token still valid, not fetching a new one");
      return;
    }
    // We either haven't gotten a token yet, or the one we
    // have has expired, so we fetch a new one.
    late final Response response;
    const timeout = Duration(seconds: 5);
    try {
      String key = apiKey ?? "";
      dlog("Fetching token from $_tokenURL (X-API-Key: $key)");
      response = await get(Uri.parse(_tokenURL), headers: {"X-API-Key": key}).timeout(timeout,
          onTimeout: () {
        dlog("Timed out while fetching token");
        return Response("Timed out", 408);
      });
      if (response.statusCode != 200) {
        throw ("Server response: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      dlog("Error while fetching WebSocket token: $e");
      _token = null;
      return;
    }
    _token = AuthenticationToken.fromJson(response.body);
    dlog("Received $_token");
  }

  /// Optional callback that provides the user's current
  /// location as WGS84 coordinates (latitude, longitude).
  List<double>? Function()? getLocation;

  // Handlers for session events

  /// Called when the session has received a greeting from
  /// the server and has begun streaming audio.
  void Function()? onStartStreaming;

  /// Called when the session has received speech text from the server.
  void Function(String, bool, Map<String, dynamic>)? onSpeechTextReceived;

  /// Called when the session has received *final* speech text
  /// from the server and is waiting for a query answer.
  void Function()? onStartQuerying;

  /// Called when the session has received a query answer from the server.
  void Function(Map<String, dynamic>)? onQueryAnswerReceived;

  /// Called when the session is playing the answer as audio.
  void Function()? onStartAnswering;

  /// Called when the session has finished playing the audio
  /// answer or has been manually ended.
  void Function()? onDone;

  /// Called when the session has encountered an error and ended.
  void Function(String)? onError;

  @override
  String toString() {
    final Map<String, dynamic> d = {
      "_tokenURL": _tokenURL,
      "socketURL": socketURL,
      "apiKey": apiKey,
      "language": language,
      "engine": engine,
      "voiceID": voiceID,
      "voiceSpeed": voiceSpeed,
      "private": privateMode,
      "clientID": clientID,
      "clientType": clientType,
      "clientVersion": clientVersion,
      "query": query,
      "tts": tts,
      "audio": audio,
      "_token": _token,
    };
    return d.toString();
  }
}
