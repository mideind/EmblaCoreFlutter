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

// Embla configuration object

import './common.dart';

/// EmblaSession configuration object
class EmblaSessionConfig {
  // Ratatoskur server URL
  String serverURL = kDefaultServer;

  // Ratatoskur API key
  String? apiKey;

  // Query server URL
  String queryServer = kDefaultQueryAPI;

  // Speech-to-text language (e.g. "is-IS")
  // Currently ignored as only is-IS is supported.
  String language = kSpeechToTextLanguage;

  // Override default engine
  String? engine;

  // Voice synthesis settings
  String voiceID = kDefaultSpeechSynthesisVoice;
  double voiceSpeed = kDefaultSpeechSynthesisSpeed;

  // We don't send client info to server in private mode
  bool private = false;

  // Client info. Should be set by client app
  // Ideally, a unique app-specific client ID should
  // be provided via e.g. the platform_device_id package.
  String? clientID;

  // Client type string (e.g. "ios", "android")
  // Third-party clients should use their own name
  // here, e.g. myappname_ios, myappname_android.
  String? clientType;

  // Client version string (e.g. "1.0.0")
  // Can be fetched via e.g. the package_info_plus package.
  String? clientVersion;

  // Whether to send ASR text to the query server and
  // forward the query response to the client.
  bool query = true;

  // Whether to play session sounds
  // TODO: Implement this
  bool audio = true;

  //// Handlers for session events ////

  // Called when the session has received a greeting from the server
  Function? onStartListening;

  // Called when the session has received speech text from the server
  Function(String, bool)? onSpeechTextReceived;

  // Called when the session has received *final* speech text from
  // the server and is waiting for a query answer.
  Function? onStartQuerying;

  // Called when the session has received a query answer from the server
  Function(Map<String, dynamic>)? onQueryAnswerReceived;

  // Called when the session is playing the answer as audio
  Function? onStartAnswering;

  // Called when the session has finished playing the audio answer
  // or has been manually ended.
  Function? onDone;

  // Called when the session has encountered an error and ended.
  Function(String)? onError;

  // Optional callback that provides the user's current location as
  // WGS84 coordinates (latitude, longitude).
  List<double> Function()? getLocation;
}
