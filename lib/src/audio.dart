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

/// Audio playback handling

import 'dart:math' show Random;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart' show Level;
import 'package:flutter_soundfork/flutter_soundfork.dart' show FlutterSoundPlayer, Codec;
// We only need this library if we're in debug mode
import 'package:mp3_info/mp3_info.dart' show MP3Processor if (kDebugMode) "";

import './api.dart';
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
  'mynameis-gudrun',
  'mynameis-gunnar',
  'voicespeed-gudrun',
  'voicespeed-gunnar',
  'nomic-gudrun',
  'nomic-gunnar',
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
const kAudioFilePath = "packages/embla_core/assets/audio/";
const kAudioFileSuffix = "wav";

// These sounds are the same regardless of voice ID settings
const List<String> sessionSounds = [
  'rec_begin',
  'rec_cancel',
  'rec_confirm',
];

/// Audio playback singleton class
class AudioPlayer {
  final FlutterSoundPlayer _player = FlutterSoundPlayer(logLevel: Level.error);
  final Map<String, Uint8List> _audioFileCache = <String, Uint8List>{};

  // Singleton pattern
  factory AudioPlayer() {
    return _instance;
  }
  AudioPlayer._constructor() {
    // Initialization only happens once
    _init();
  }
  static final AudioPlayer _instance = AudioPlayer._constructor();

  // Audio player setup and audio data preloading
  Future<void> _init() async {
    dlog('Initing audio player');
    await _preloadAudioFiles();
    await _player.openPlayer();
  }

  // Load all asset-bundled audio files into memory
  Future<void> _preloadAudioFiles() async {
    dlog("Preloading audio assets (${audioFiles.length} files)");
    for (String fn in audioFiles) {
      final ByteData bytes = await rootBundle.load("$kAudioFilePath$fn.$kAudioFileSuffix");
      _audioFileCache[fn] = bytes.buffer.asUint8List();
    }
  }

  /// Stop all playback.
  void stop() {
    if (_player.isPlaying == false) {
      return;
    }
    dlog('Stopping audio playback');
    _player.stopPlayer();
  }

  /// Play remote audio file at URL.
  ///
  /// [url] URL of audio file
  /// [completionHandler] Completion handler invoked when playback is finished.
  /// The bool parameter is true if an error occurred.
  Future<void> playURL(String url, [void Function(bool err)? completionHandler]) async {
    //stop();
    // If the URL is too long (maybe a Data URI?), truncate it for logging purposes
    String displayURL = url;
    if (url.length > 200) {
      displayURL = "${url.substring(0, 200)}...";
    }

    dlog("Playing audio file at URL '$displayURL'");
    try {
      late Uint8List data;
      final Uri uri = Uri.parse(url);

      if (uri.scheme == 'data') {
        // We support data URIs (RFC 2397)
        final UriData dataURI = UriData.fromUri(uri);
        data = dataURI.contentAsBytes();
      } else {
        // Otherwise, we download the file
        data = await http.readBytes(Uri.parse(url));
      }

      // We expect the file to be an MP3
      if (kDebugMode) {
        final mp3 = MP3Processor.fromBytes(data);
        final double sec = mp3.duration.inMilliseconds / 1000.0;
        dlog("Audio file is ${data.lengthInBytes} bytes (${sec.toStringAsFixed(1)} seconds)");
      }

      _player.setSpeed(kDefaultSpeechSynthesisSpeed);
      _player.startPlayer(
          fromDataBuffer: data,
          codec: Codec.mp3,
          whenFinished: () {
            if (completionHandler != null) {
              completionHandler(false);
            }
          });
    } catch (e) {
      dlog('Error downloading remote file: $e');
      if (completionHandler != null) {
        completionHandler(true);
      }
    }
  }

  /// Play a random "don't know" audio recording.
  ///
  /// [voiceID] Voice ID to use
  /// [completionHandler] Callback invoked when playback is finished
  /// [playbackSpeed] Playback speed
  String? playDunno(String voiceID,
      [void Function()? completionHandler, double playbackSpeed = kDefaultSpeechSynthesisSpeed]) {
    final int rand = Random().nextInt(7) + 1;
    final String num = rand.toString().padLeft(2, '0');
    final String fn = "dunno$num";

    playSound(fn, voiceID, completionHandler!, playbackSpeed);

    const Map<String, String> dunnoStrings = {
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

  /// Play the UI sound for starting a new session.
  void playSessionStart() {
    playSound('rec_begin');
  }

  /// Play the UI sound for when an answer is confirmed.
  void playSessionConfirm() {
    playSound('rec_confirm');
  }

  /// Play the UI sound for when a session is canceled or fails.
  void playSessionCancel() {
    playSound('rec_cancel');
  }

  /// Play the sound for when the app does not have microphone recording permissions.
  void playNoMic({String voiceID = kDefaultSpeechSynthesisVoice, double voiceSpeed = kDefaultSpeechSynthesisSpeed}) {
    playSound('nomic', voiceID, null, voiceSpeed);
  }

  /// Play a preloaded audio file bundled with the app.
  /// Some of these audio files are voice-dependent, and will be played with
  /// the specified voice ID, e.g. `playSound('conn', 'Gunnar')` will play
  /// the Gunnar voice version of the "conn" audio recording ('conn-gunnar'), etc.
  ///
  /// [soundName] Name of the audio file to play
  /// [voiceID] Voice ID to use for the audio file (only applies to voice-dependent files)
  /// [completionHandler] Completion handler to call when playback is finished
  /// [playbackSpeed] Playback speed (1.0 = normal speed)
  void playSound(String soundName,
      [String voiceID = kDefaultSpeechSynthesisVoice,
      void Function()? completionHandler,
      double playbackSpeed = kDefaultSpeechSynthesisSpeed]) {
    stop();

    // Different filename depending on voice
    String fileName = soundName;
    if (sessionSounds.contains(soundName) == false) {
      // Guðrún --> gudrun, Gunnar --> gunnar, etc.
      String voiceName = voiceID.toLowerCase().asciify();
      fileName = "$soundName-$voiceName";
    }

    // Make sure the file is in the cache
    if (_audioFileCache.containsKey(fileName) == false) {
      dlog("Warning! Audio file '$fileName' not found in cache.");
      return;
    }

    dlog("Playing audio file '$fileName.wav'");
    _player.setSpeed(playbackSpeed);
    _player.startPlayer(
        fromDataBuffer: _audioFileCache[fileName],
        sampleRate: kAudioSampleRate,
        whenFinished: completionHandler);
  }

  /// Synthesize speech from text via API and play the
  /// resulting audio file at the returned URL.
  /// If an error occurs, the completion handler is called with true.
  ///
  /// [text] The text to synthesize into speech
  /// [apiKey] Required API key
  /// [ttsOptions] Text-to-speech options
  /// [transcriptionOptions] Transcription options
  /// [completionHandler] Completion handler called when playback is finished
  void speak(String text, String apiKey,
      {SpeechOptions? ttsOptions,
      TranscriptionOptions? transcriptionOptions,
      bool transcribe = true,
      void Function(bool err)? completionHandler}) async {
    stop();
    await EmblaAPI.synthesizeSpeech(text, apiKey, transcribe: transcribe, ttsOptions: ttsOptions, transcriptionOptions: transcriptionOptions)
        .then((dynamic url) {
      if (url == null) {
        // Something went wrong
        if (completionHandler != null) {
          completionHandler(true);
        }
      } else {
        playURL(url, completionHandler);
      }
    });
  }
}
