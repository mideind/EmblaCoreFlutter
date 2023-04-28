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

/// Speech synthesis

import 'dart:convert' show json;

import 'package:http/http.dart' show post;

import './common.dart';

/// Speech synthesizer static class
class EmblaSpeechSynthesizer {
  // Disable instantiation
  EmblaSpeechSynthesizer._();

  /// Send request to speech synthesis API (static method).
  ///
  /// [text] Text to be speech synthesized
  /// [apiKey] Server API key
  /// Returns the resulting audio file URL or null if an error occurred.
  static Future<String?> synthesize(String text, String? apiKey,
      {String voiceID = kDefaultSpeechSynthesisVoice,
      double voiceSpeed = kDefaultSpeechSynthesisSpeed,
      String apiURL = "$kDefaultServer$kSpeechSynthesisEndpoint"}) async {
    // Set URI
    Uri uri;
    try {
      uri = Uri.parse(apiURL);
    } on FormatException {
      dlog("Invalid URL specified for TTS synthesis.");
      return null;
    }
    // Set request headers
    Map<String, String> headers = {
      "X-API-Key": apiKey ?? "",
      "content-type": "application/json",
      "accept": "application/json"
    };
    // Set request body
    String body = json.encode({
      'text': text,
      'options': {'voice_id': voiceID, 'voice_speed': voiceSpeed.toString()}
    });

    dlog("Sending POST request to $apiURL: $body");
    return await post(uri, headers: headers, body: body).timeout(kRequestTimeout).then((response) {
      dlog("Response status: ${response.statusCode}");
      dlog("Response body: ${response.body}");
      if (response.statusCode != 200) {
        dlog("Received invalid status code from TTS service.");
        return null;
      }

      dynamic arg = json.decode(response.body);
      if (arg is Map && arg.containsKey("audio_url")) {
        // Valid response body
        // Return the resulting audio file URL
        return arg["audio_url"];
      }
      dlog("Invalid response body from TTS service.");
      return null;
    }, onError: (e) {
      dlog("Error in speech synthesis: $e");
      // Errors during request, return null
      return null;
    });
  }
}
