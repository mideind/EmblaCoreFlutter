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

/// Communication with the Embla API (Ratatoskur)

import 'dart:convert' show json;

import 'package:http/http.dart' show Response;
import 'package:http/http.dart' as http;

import './common.dart';

/// Static class wrapper for functions communicating
/// directly with the Embla API.
class EmblaAPI {
  /// Send request to clear query history for a given device ID.
  ///
  /// Boolean [allData] param determines whether all device-specific
  /// data or only query history should be deleted server-side.
  static Future<void> clearUserData(String deviceID, String apiKey,
      {bool allData = false,
      String serverURL = kDefaultServer,
      void Function(Map? result)? completionHandler}) async {
    final Map<String, String> qargs = {
      'action': allData ? 'clear_all' : 'clear',
      'client_id': deviceID,
    };

    final String apiURL = "$serverURL$kClearHistoryEndpoint";
    await _makePOSTRequest(apiURL, apiKey, qargs, completionHandler);
  }

  /// Send request to speech synthesis API (static method).
  ///
  /// [text] Text to be speech synthesized
  /// [apiKey] Server API key
  ///
  /// Returns the resulting audio file URL or null if an error occurred.
  static Future<String?> synthesizeSpeech(String text, String? apiKey,
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
      "Content-Type": "application/json",
      "Accept": "application/json"
    };
    // Set request body
    String body = json.encode({
      'text': text,
      'options': {'voice_id': voiceID, 'voice_speed': voiceSpeed.toString()}
    });

    dlog("Sending POST request to $apiURL: $body");
    return await http.post(uri, headers: headers, body: body).timeout(kRequestTimeout).then(
        (response) {
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

  /// Send JSON POST request to API server.
  static Future<Response?> _makePOSTRequest(
      String apiURL, String apiKey, Map<String, dynamic> qargs,
      [void Function(Map? result)? handler]) async {
    dlog("Sending query POST request to $apiURL: ${qargs.toString()}");
    Response? response;
    try {
      final Map<String, String> headers = {
        "X-API-Key": apiKey,
        "Content-Type": "application/json",
        "Accept": "application/json"
      };
      response = await http
          .post(Uri.parse(apiURL), body: json.encode(qargs), headers: headers)
          .timeout(kRequestTimeout, onTimeout: () {
        handler!(null);
        return Response("Request timed out", 408);
      });
    } catch (e) {
      dlog("Error while making POST request: $e");
      response = null;
    }

    // Handle null response
    if (response == null) {
      if (handler != null) {
        handler(null);
      }
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
