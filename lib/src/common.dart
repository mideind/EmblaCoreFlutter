/*
 * This file is part of the EmblaCore Flutter package
 *
 * Copyright (c) 2024 Miðeind ehf. <mideind@mideind.is>
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

/// Global constants

import 'package:flutter/foundation.dart' show kDebugMode;

const String kEmblaCoreName = 'EmblaCore';
const String kEmblaCoreVersion = '1.0.9';

// Speech recognition settings
const String kDefaultSpeechToTextLanguage = 'is-IS';

// Audio recording settings
const int kAudioSampleRate = 16000;
const int kAudioBitRate = 16;
const int kAudioNumChannels = 1;

// Server communication
const String kDefaultServer = "https://api.mideind.is";
const String kDefaultQueryServer = 'https://greynir.is';
const String kTokenEndpoint = "/rat/v1/token";
const String kSocketEndpoint = "/rat/v1/short_asr";
const String kQueryEndpoint = "/rat/v1/query";
const String kSpeechSynthesisEndpoint = "/rat/v2/tts";
const String kClearHistoryEndpoint = "/rat/v1/clear_history";

const kRequestTimeout = Duration(seconds: 10); // Seconds

// Speech synthesis
const double kDefaultSpeechSynthesisSpeed = 1.0;
const String kDefaultSpeechSynthesisVoice = "Guðrún";
const List<String> kSupportedSpeechSynthesisVoices = [
  "Guðrún",
  "Gunnar",
];
const String kDefaultSpeechSynthesisTextFormat = "ssml";
const String kDefaultSpeechSynthesisAudioFormat = "mp3";

/// Debug logging
void dlog(dynamic msg) {
  if (kDebugMode == true) {
    // ignore: avoid_print
    print(msg.toString());
  }
}

class SpeechOptions {
  String voice;
  double speed;
  String textFormat;
  String audioFormat;

  SpeechOptions(
      {this.voice = kDefaultSpeechSynthesisVoice,
      this.speed = kDefaultSpeechSynthesisSpeed,
      this.textFormat = kDefaultSpeechSynthesisTextFormat,
      this.audioFormat = kDefaultSpeechSynthesisAudioFormat});

  Map<String, dynamic> toJson() {
    return {
      'voice': voice,
      'speed': speed,
      'text_format': textFormat,
      'audio_format': audioFormat,
    };
  }
}

class TranscriptionOptions {
  bool? emails;
  bool? dates;
  bool? years;
  bool? domains;
  bool? urls;
  bool? amounts;
  bool? measurements;
  bool? percentages;
  bool? numbers;
  bool? ordinals;

  TranscriptionOptions(
      {this.emails,
      this.dates,
      this.years,
      this.domains,
      this.urls,
      this.amounts,
      this.measurements,
      this.percentages,
      this.numbers,
      this.ordinals});

  Map<String, dynamic> toJson() {
    final map = {
      'emails': emails,
      'dates': dates,
      'years': years,
      'domains': domains,
      'urls': urls,
      'amounts': amounts,
      'measurements': measurements,
      'percentages': percentages,
      'numbers': numbers,
      'ordinals': ordinals,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }
}
