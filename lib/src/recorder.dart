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

/// Audio recording wrapper class
///
/// This code assumes that microphone access has already been granted
/// by the user. Clients are responsible for requesting access prior
/// to instantiation and should not use this class if access has not
/// been granted. Caveat emptor.

import 'dart:async';
import 'dart:math' show pow;

import 'package:flutter/foundation.dart' show Uint8List;

import 'package:logger/logger.dart' show Level;
import 'package:flutter_sound/flutter_sound.dart';

import './common.dart';

/// Audio recording singleton class
class AudioRecorder {
  final FlutterSoundRecorder _micRecorder = FlutterSoundRecorder(logLevel: Level.error);
  StreamSubscription? _recordingDataSubscription;
  StreamSubscription? _recordingProgressSubscription;
  StreamController? _recordingDataController;

  bool _isRecording = false; // Are we currently recording?
  double _lastSignal = 0.0; // Strength of last audio signal, on a scale of 0.0 to 1.0
  int _totalAudioDataSize = 0; // Accumulated byte size of audio recording
  double _totalAudioDuration = 0.0; // Accumulated duration of audio recording, in seconds

  AudioRecorder._constructor();
  static final AudioRecorder _instance = AudioRecorder._constructor();
  factory AudioRecorder() {
    _instance._micRecorder.openRecorder();
    return _instance;
  }

  /// Returns the duration of the recorded audio in seconds.
  double duration() {
    return _totalAudioDuration;
  }

  /// Returns the size of the recorded audio in bytes.
  int audioSize() {
    return _totalAudioDataSize;
  }

  /// Returns the normalized signal strength of the last
  /// recorded audio samples (on a scale of 0.0 to 1.0).
  double signalStrength() {
    return _lastSignal;
  }

  /// Returns true if we are currently recording.
  bool isRecording() {
    return _isRecording;
  }

  /// Start recording audio from microphone.
  Future<void> start(void Function(Uint8List) dataHandler, void Function(String) errHandler) async {
    if (_isRecording == true) {
      const errMsg = 'EmblaRecorder already recording!';
      dlog(errMsg);
      errHandler(errMsg);
      return;
    }

    dlog('Starting recording');
    _isRecording = true;

    // Create recording stream
    _recordingDataController = StreamController<Food>();
    _recordingDataSubscription = _recordingDataController?.stream.listen((buffer) {
      if (buffer is FoodData && buffer.data != null) {
        final data = buffer.data as Uint8List;
        _totalAudioDataSize += data.lengthInBytes;
        _totalAudioDuration = _totalAudioDataSize / (kAudioSampleRate * 2);
        dataHandler(data); // Invoke callback
        dlog(_totalAudioDuration);
      } else {
        final errMsg = 'Got null data in recording stream: $buffer';
        dlog(errMsg);
        errHandler(errMsg);
      }
    });

    // Open microphone recording session
    // await _micRecorder.openRecorder();

    // Listen for audio status (duration, decibel) at fixed interval
    await _micRecorder.setSubscriptionDuration(const Duration(milliseconds: 80));
    _recordingProgressSubscription = _micRecorder.onProgress?.listen((e) {
      if (e.decibels == 0.0) {
        return; // Hack to work around a bug in flutter_sound
      }
      // dlog(e);
      final double decibels = e.decibels! - 70.0; // This number is arbitrary but works
      _lastSignal = _normalizedSignalStrengthFromDecibels(decibels);
    });

    // Start recording audio
    await _micRecorder.startRecorder(
        toStream: _recordingDataController?.sink as StreamSink<Food>,
        codec: Codec.pcm16,
        numChannels: kAudioNumChannels,
        sampleRate: kAudioSampleRate);
  }

  /// Stop recording and clean up.
  Future<void> stop() async {
    if (_isRecording == false) {
      return;
    }

    _isRecording = false;

    dlog('Stopping audio recording');
    dlog("Total audio length: ${_totalAudioDuration.toStringAsFixed(1)}"
        " seconds ($_totalAudioDataSize bytes)");

    _lastSignal = 0.0;
    _totalAudioDataSize = 0;
    _totalAudioDuration = 0.0;

    await _recordingDataSubscription?.cancel();
    await _recordingProgressSubscription?.cancel();
    await _recordingDataController?.close();

    await _micRecorder.stopRecorder();
    // await _micRecorder.closeRecorder();
  }

  // Normalize decibel level to a number between 0.0 and 1.0
  double _normalizedSignalStrengthFromDecibels(double decibels) {
    if (decibels < -60.0 || decibels == 0.0) {
      return 0.0;
    }
    const double exp = 0.05;
    return pow(
        (pow(10.0, exp * decibels) - pow(10.0, exp * -60.0)) *
            (1.0 / (1.0 - pow(10.0, exp * -60.0))),
        1.0 / 2.0) as double;
  }
}
