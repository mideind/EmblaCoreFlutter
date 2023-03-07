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

// Audio playback handling

import 'dart:typed_data';
import 'dart:math' show Random;

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart' show Level;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart' show FlutterSoundPlayer, Codec;

import './util.dart';
import './common.dart';

// List of audio file assets in bundle
const List<String> audioFiles = [
  // Voice-independent
  'rec_begin',
  'rec_cancel',
  'rec_confirm',
  // Voice dependent
  'conn-gudrun',
  'conn-gunnar',
  'err-gudrun',
  'err-gunnar',
  'dunno01-gudrun',
  'dunno02-gudrun',
  'dunno03-gudrun',
  'dunno04-gudrun',
  'dunno05-gudrun',
  'dunno06-gudrun',
  'dunno07-gudrun',
  'dunno01-gunnar',
  'dunno02-gunnar',
  'dunno03-gunnar',
  'dunno04-gunnar',
  'dunno05-gunnar',
  'dunno06-gunnar',
  'dunno07-gunnar',
];

// These sounds are the same regardless of voice ID settings.
const List<String> sessionSounds = [
  'rec_begin',
  'rec_cancel',
  'rec_confirm',
];

/// Singleton class that handles all audio playback
class AudioPlayer {
  final FlutterSoundPlayer player = FlutterSoundPlayer(logLevel: Level.error);
  final Map<String, Uint8List> audioFileCache = <String, Uint8List>{};

  // Singleton pattern
  factory AudioPlayer() {
    return _instance;
  }
  AudioPlayer._internal() {
    // Initialization, which only happens once
    _init();
  }
  static final AudioPlayer _instance = AudioPlayer._internal();

  /// Audio player setup and audio data preloading
  Future<void> _init() async {
    dlog('Initing audio player');
    await _preloadAudioFiles();
    await player.openPlayer();
  }

  /// Load all asset-bundled audio files into memory
  Future<void> _preloadAudioFiles() async {
    dlog("Preloading audio assets (${audioFiles.length} files)");
    for (String fn in audioFiles) {
      ByteData bytes = await rootBundle.load("packages/embla_core/assets/audio/$fn.wav");
      audioFileCache[fn] = bytes.buffer.asUint8List();
    }
  }

  /// Stop all playback
  void stop() {
    dlog('Stopping audio playback');
    player.stopPlayer();
  }

  /// Play remote audio file
  Future<void> playURL(String url, Function(bool err) completionHandler) async {
    //stop();

    dlog("Playing audio file at URL '$url'");
    try {
      Uint8List data;
      Uri uri = Uri.parse(url);

      if (uri.scheme == 'data') {
        // We support data URIs
        UriData dataURI = UriData.fromUri(uri);
        data = dataURI.contentAsBytes();
      } else {
        // Otherwise, we download the file
        data = await http.readBytes(Uri.parse(url));
      }
      dlog("Audio file is ${data.lengthInBytes} bytes");

      player.setSpeed(1.0);
      player.startPlayer(
          fromDataBuffer: data,
          codec: Codec.mp3,
          whenFinished: () {
            completionHandler(false);
          });
    } catch (e) {
      dlog('Error downloading remote file: $e');
      completionHandler(true);
    }
  }

  /// Play a random "don't know" response
  String? playDunno(String voiceID, [Function()? completionHandler, double playbackSpeed = 1.0]) {
    int rnd = Random().nextInt(7) + 1;
    String num = rnd.toString().padLeft(2, '0');
    String fn = "dunno$num";

    playSound(fn, voiceID, completionHandler!, playbackSpeed);

    Map<String, String> dunnoStrings = {
      "dunno01": "Ég get ekki svarað því.",
      "dunno02": "Ég get því miður ekki svarað því.",
      "dunno03": "Ég kann ekki svar við því.",
      "dunno04": "Ég skil ekki þessa fyrirspurn.",
      "dunno05": "Ég veit það ekki.",
      "dunno06": "Því miður skildi ég þetta ekki.",
      "dunno07": "Því miður veit ég það ekki.",
    };
    return dunnoStrings[fn];
  }

  void playSessionStart() {
    playSound('rec_begin');
  }

  void playSessionConfirm() {
    playSound('rec_confirm');
  }

  void playSessionCancel() {
    playSound('rec_cancel');
  }

  /// Play a preloaded audio file bundled with the app
  void playSound(String soundName,
      [String voiceID = kDefaultSpeechSynthesisVoice,
      Function()? completionHandler,
      double playbackSpeed = 1.0]) {
    stop();

    // Different file name depending on voice
    String fileName = soundName;
    if (sessionSounds.contains(soundName) == false) {
      String voiceName = voiceID.toLowerCase().asciify();
      fileName = "$soundName-$voiceName";
    }

    // Make sure the file is in the cache
    if (audioFileCache.containsKey(fileName) == false) {
      dlog("Audio file '$fileName' not found in cache!");
      return;
    }

    dlog("Playing audio file '$fileName.wav'");
    player.setSpeed(playbackSpeed);
    player.startPlayer(
        fromDataBuffer: audioFileCache[fileName],
        sampleRate: kAudioSampleRate,
        whenFinished: () {
          if (completionHandler != null) {
            completionHandler();
          }
        });
  }
}
