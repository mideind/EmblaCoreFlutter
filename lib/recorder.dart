/*
 * This file is part of the EmblaCore Flutter package
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

import 'dart:async';
import 'dart:math' show pow;

import 'package:flutter/foundation.dart' show Uint8List;

import 'package:logger/logger.dart' show Level;
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sound/flutter_sound.dart';

import './common.dart';

class EmblaAudioRecorder {
  final FlutterSoundRecorder _micRecorder = FlutterSoundRecorder(logLevel: Level.error);
  StreamSubscription? _recordingDataSubscription;
  StreamSubscription? _recordingProgressSubscription;
  StreamController? _recordingDataController;

  bool isRecording = false;
  double lastSignal = 0.0; // Strength of last audio signal, on a scale of 0.0 to 1.0
  int totalAudioDataSize = 0; // Accumulated byte size of audio recording

  // TODO: Implement singleton pattern?

  // Do we have permissions to record audio?
  Future<bool> hasPermissions() async {
    // TBD: Check for microphone permission
    return true;
  }

  // Normalize decibel level to a number between 0.0 and 1.0
  double _normalizedPowerLevelFromDecibels(double decibels) {
    if (decibels < -60.0 || decibels == 0.0) {
      return 0.0;
    }
    const double exp = 0.05;
    return pow(
        (pow(10.0, exp * decibels) - pow(10.0, exp * -60.0)) *
            (1.0 / (1.0 - pow(10.0, exp * -60.0))),
        1.0 / 2.0) as double;
  }

  // Start recording audio from microphone
  Future<void> start(void Function(Uint8List) dataHandler, Function errHandler) async {
    if (isRecording == true) {
      dlog('EmblaRecorder already recording');
      return;
    }
    dlog('Starting recording');
    isRecording = true;
    totalAudioDataSize = 0;

    // Create recording stream
    _recordingDataController = StreamController<Food>();
    _recordingDataSubscription = _recordingDataController?.stream.listen((buffer) {
      if (buffer is FoodData && buffer.data != null) {
        // TODO: This is where we should send the audio data to server
        var data = buffer.data as Uint8List;
        // dataHandler(data)
        totalAudioDataSize += buffer.data!.lengthInBytes;
      } else {
        dlog('Got null data in recording stream: $buffer');
      }
    });

    // Open microphone recording session
    await _micRecorder.openRecorder();

    // Configure audio session
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

    // Listen for audio status (duration, decibel) at fixed interval
    _micRecorder.setSubscriptionDuration(Duration(milliseconds: 50));
    _recordingProgressSubscription = _micRecorder.onProgress?.listen((e) {
      if (e.decibels == 0.0) {
        return;
      }
      dlog(e);
      double decibels = e.decibels! - 70.0; // This number is arbitrary but works
      lastSignal = _normalizedPowerLevelFromDecibels(decibels);
    });

    // Start recording audio
    await _micRecorder.startRecorder(
        toStream: _recordingDataController?.sink as StreamSink<Food>,
        codec: Codec.pcm16,
        numChannels: kAudioNumChannels,
        sampleRate: kAudioSampleRate);
  }

  // Teardown
  Future<void> stop() async {
    if (isRecording == false) {
      return;
    }
    isRecording = false;
    dlog('Stopping audio recording');
    final double seconds = totalAudioDataSize / (2.0 * kAudioSampleRate);
    dlog("Total audio length: $seconds seconds ($totalAudioDataSize bytes)");
    await _micRecorder.stopRecorder();
    await _micRecorder.closeRecorder();
    await _recordingDataSubscription?.cancel();
    await _recordingProgressSubscription?.cancel();
    await _recordingDataController?.close();
  }
}
