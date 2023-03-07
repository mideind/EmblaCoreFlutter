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

// Code relating to speech synthesis

import 'dart:convert' show json;

import 'package:http/http.dart' show Response;
import 'package:http/http.dart' as http;

import './common.dart';

const kRequestTimeout = Duration(seconds: 10); // Seconds

class EmblaSpeechSynthesizer {
  /// Send request to speech synthesis API
  Future<void> synthesize(String text, String apiKey,
      [String voiceID = kDefaultSpeechSynthesisVoice,
      double voiceSpeed = kDefaultSpeechSynthesisSpeed,
      Function(Map?)? handler]) async {
    Map<String, String> qargs = {
      'text': text,
      'api_key': apiKey,
      'voice_id': voiceID,
      'voice_speed': voiceSpeed.toString(),
      //'format': 'text',
    };

    await _makeRequest(kDefaultSpeechSynthesisAPI, qargs, handler);
  }

  Future<Response?> _makeRequest(String apiURL, Map<String, dynamic> qargs,
      [Function(Map?)? handler]) async {
    dlog("Sending query POST request to $apiURL: ${qargs.toString()}");
    Response? response;
    try {
      response =
          await http.post(Uri.parse(apiURL), body: qargs).timeout(kRequestTimeout, onTimeout: () {
        handler!(null);
        return Response("Request timed out", 408);
      });
    } catch (e) {
      dlog("Error while making POST request: $e");
      response = null;
    }

    // Handle null response
    if (response == null) {
      handler!(null);
      return null;
    }

    // We have a valid response object
    dlog("Response status: ${response.statusCode}");
    dlog("Response body: ${response.body}");
    if (handler != null) {
      // Parse JSON body and feed ensuing data structure to handler function
      dynamic arg = (response.statusCode == 200) ? json.decode(response.body) : null;
      // JSON response should be a dict, otherwise something's gone horribly wrong
      arg = (arg is Map) == false ? null : arg;
      handler(arg);
    }

    return response;
  }
}