/*
 * This file is part of the Embla Flutter app
 * Copyright (c) 2020-2022 Miðeind ehf. <mideind@mideind.is>
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

// Audio playback

import 'dart:async';
import 'dart:typed_data';

import 'package:logger/logger.dart' show Level;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;

import './common.dart';

// Singleton class that handles all audio playback
class AudioPlayer {
  FlutterSoundPlayer? player;

  // Constructor
  static final AudioPlayer _instance = AudioPlayer._internal();

  // Singleton pattern
  factory AudioPlayer() {
    return _instance;
  }

  // Initialization
  AudioPlayer._internal() {
    _init();
  }

  // Audio player setup and audio data preloading
  Future<void> _init() async {
    dlog('Initing audio player');
    player = FlutterSoundPlayer(logLevel: Level.error);
    await player!.openPlayer();
  }

  // Stop playback
  void stop() {
    dlog('Stopping audio playback');
    player?.stopPlayer();
  }

  // Play remote audio file
  Future<void> playURL(String url, Function(bool) completionHandler) async {
    //_instance.stop();

    dlog("Playing audio file URL '${url.substring(0, 200)}'");
    try {
      Uint8List data;
      Uri uri = Uri.parse(url);

      if (uri.scheme == 'data') {
        UriData dataURI = UriData.fromUri(uri);
        data = dataURI.contentAsBytes();
      } else {
        data = await http.readBytes(Uri.parse(url));
      }
      dlog("Audio file is ${data.lengthInBytes} bytes");

      player!.startPlayer(
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
}
