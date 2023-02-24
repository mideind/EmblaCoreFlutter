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

class EmblaSessionConfig {
  // Query server URL
  String queryServer = kDefaultQueryServer;

  // Voice synthesis properties
  String voiceID = kDefaultSpeechSynthesisVoice;
  double voiceSpeed = kDefaultSpeechSynthesisSpeed;

  bool private = false; // Don't send client info to server
  bool test = false; // This is a test query (not logged, uses dummy location data)

  // User's GPS coordinates (optional)
  double? latitude;
  double? longitude;

  // Whether to play session sounds
  // TODO: Implement this
  bool audio = true;

  // Handlers for session events
  Function? onStartListening;
  Function(List<String>, bool)? onSpeechTextReceived;

  Function? onStartQuerying;
  Function(Map<String, dynamic>)? onQueryAnswerReceived;

  Function? onStartAnswering;

  Function? onDone;
  Function(String)? onError;

  EmblaSessionConfig(
      {String queryServer = kDefaultQueryServer,
      String voiceID = kDefaultSpeechSynthesisVoice,
      double voiceSpeed = kDefaultSpeechSynthesisSpeed,
      bool private = false,
      bool test = false,
      double? latitude,
      double? longitude}) {
    this.queryServer = queryServer;
    this.voiceID = voiceID;
    this.voiceSpeed = voiceSpeed;
    this.private = private;
    this.test = test;
    this.latitude = latitude;
    this.longitude = longitude;
  }
}
