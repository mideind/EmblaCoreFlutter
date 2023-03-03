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

// ignore_for_file: prefer_initializing_formals

import './common.dart';

/// EmblaSession configuration object
class EmblaSessionConfig {
  String serverURL = kDefaultServer;
  String queryServer = kDefaultQueryServer;
  String language = kSpeechToTextLanguage;
  String? engine;

  // Voice synthesis properties
  String voiceID = kDefaultSpeechSynthesisVoice;
  double voiceSpeed = kDefaultSpeechSynthesisSpeed;

  // Don't send client info to server
  bool private = false;

  // Client info. Should be set by client app
  String? clientID;
  String? clientType;
  String? clientVersion;
  double? latitude;
  double? longitude;

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

  // Called when the session has finished playing the answer as audio
  // or has been manually stopped.
  Function? onDone;

  // Called when the session has encountered an error
  Function(String)? onError;

  // Optional callback that provides the user's current location in WGS84
  List<double> Function()? getLocation;
}
