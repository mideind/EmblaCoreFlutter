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

// Global constants and debug logging

import 'package:flutter/foundation.dart' show kDebugMode;

// Speech recognition settings
const String kSpeechToTextLanguage = 'is-IS';

// Audio recording settings
const int kAudioSampleRate = 16000;
const int kAudioBitRate = 16;
const int kAudioNumChannels = 1;

// Server communication
const String kDefaultServer = "brandur.mideind.is:8080";
const String kDefaultWebSocketSchema = "ws";
const String kDefaultHTTPSchema = "http";
const String kDefaultSocketEndpoint = '$kDefaultWebSocketSchema://$kDefaultServer/v1/socket';
const String kDefaultTokenEndpoint = '$kDefaultHTTPSchema://$kDefaultServer/v1/token';
const String kDefaultSpeechSynthesisAPI = '$kDefaultHTTPSchema://$kDefaultServer/v1/tts';
const String kDefaultQueryAPI = 'https://greynir.is/query.api';

const kRequestTimeout = Duration(seconds: 10); // Seconds

// Speech synthesis
const double kDefaultSpeechSynthesisSpeed = 1.0;
const String kDefaultSpeechSynthesisVoice = "Guðrún";
const List<String> kSupportedSpeechSynthesisVoices = [
  "Guðrún",
  "Gunnar",
];

// Debug logging
void dlog(dynamic msg) {
  if (kDebugMode == true) {
    // ignore: avoid_print
    print(msg.toString());
  }
}
